import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/poll/poll_bloc.dart';
import '../blocs/poll/poll_event.dart';
import '../models/poll_model.dart';
import '../models/wine_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  _CreatePollScreenState createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<_WineInput> _wines = [];

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _addWineInput() {
    setState(() => _wines.add(_WineInput()));
  }

  void _removeWineInput(int index) {
    setState(() => _wines.removeAt(index));
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _wines[index].imageFile = File(picked.path);
      });
    }
  }

  void _createPoll() async {
    final title = _titleController.text;
    if (title.isEmpty || _wines.isEmpty) return;

    final poll = Poll(
      id: '', // Se asignará en Firestore
      title: title,
      date: _selectedDate,
      creatorId: 'currentUserId',
      closed: false,
    );

    final firestore = RepositoryProvider.of<FirestoreService>(context);
    final storage = RepositoryProvider.of<StorageService>(context);

    // Crea la votación primero en Firestore y obtén el ID generado
    final pollId = await firestore.createPoll(poll);

    final wines = <Wine>[];

    for (int i = 0; i < _wines.length; i++) {
      final input = _wines[i];
      if (input.name.text.isEmpty || input.imageFile == null) continue;

      final wineId = '${DateTime.now().millisecondsSinceEpoch}_$i';

      // Sube la imagen y obtiene la URL
      final imageUrl = await storage.uploadWineImage(
        pollId,
        wineId,
        input.imageFile!,
      );

      wines.add(
        Wine(
          id: wineId,
          name: input.name.text,
          description: input.description.text,
          imageUrl: imageUrl,
          pollId: pollId,
        ),
      );
    }

    // Asocia los vinos a la votación
    await firestore.addWinesToPoll(pollId, wines);

    // Opcional: emite evento si quieres actualizar estado en BLoC
    BlocProvider.of<PollBloc>(context).add(RefreshPolls());

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _addWineInput();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Votación')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Título de la votación'),
            ),
            Row(
              children: [
                Text(
                  'Fecha: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: Text('Seleccionar fecha'),
                ),
              ],
            ),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _wines.length,
              itemBuilder: (context, index) {
                final wine = _wines[index];
                return Column(
                  key: ValueKey(wine),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: wine.name,
                      decoration: InputDecoration(labelText: 'Nombre del vino'),
                    ),
                    TextField(
                      controller: wine.description,
                      decoration: InputDecoration(labelText: 'Descripción'),
                    ),
                    Row(
                      children: [
                        wine.imageFile != null
                            ? Image.file(
                                wine.imageFile!,
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 60,
                                width: 60,
                                color: Colors.grey,
                              ),
                        TextButton(
                          onPressed: () => _pickImage(index),
                          child: Text('Seleccionar imagen'),
                        ),
                        IconButton(
                          onPressed: () => _removeWineInput(index),
                          icon: Icon(Icons.delete),
                        ),
                      ],
                    ),
                    Divider(),
                  ],
                );
              },
            ),
            TextButton.icon(
              onPressed: _addWineInput,
              icon: Icon(Icons.add),
              label: Text('Añadir vino'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _createPoll, child: Text('Crear')),
          ],
        ),
      ),
    );
  }
}

class _WineInput {
  final name = TextEditingController();
  final description = TextEditingController();
  File? imageFile;
}
