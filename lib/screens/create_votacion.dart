import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wine_app/models/vino.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';

class CreateVotacionScreen extends StatefulWidget {
  const CreateVotacionScreen({super.key});

  @override
  State<CreateVotacionScreen> createState() => _CreateVotacionScreenState();
}

class _CreateVotacionScreenState extends State<CreateVotacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final List<_VinoInput> _vinos = [_VinoInput()];
  DateTime? _fecha;
  bool fechaObligatoria = false;
  bool vinosValidos = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva votación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la votación',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _fecha = date;
                        fechaObligatoria = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _fecha == null
                        ? 'Seleccionar fecha'
                        : _fecha!.toLocal().toString().split(' ')[0],
                    style: TextStyle(
                      color: fechaObligatoria ? Colors.red : Colors.black,
                      fontWeight: _fecha == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (fechaObligatoria)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'La fecha es obligatoria',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              ..._vinos.map((vino) => vino.build(context)),
              TextButton(
                onPressed: () => setState(() => _vinos.add(_VinoInput())),
                child: const Text('Agregar vino'),
              ),
              if (!vinosValidos)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Debe haber al menos un vino válido (nombre, descripción y precio)',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  bool hasError = false;

                  if (!_formKey.currentState!.validate()) return;

                  if (_fecha == null) {
                    setState(() => fechaObligatoria = true);
                    hasError = true;
                  }

                  final creador = auth.currentUser!.uid;
                  final vinos = <Vino>[];

                  vinosValidos = false;

                  for (var v in _vinos) {
                    v.validate();
                    if (v.isValid()) vinosValidos = true;
                  }

                  if (!vinosValidos) {
                    hasError = true;
                  }

                  setState(() {});

                  if (hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Revisa los campos obligatorios'),
                      ),
                    );
                    return;
                  }

                  for (var v in _vinos) {
                    if (v.isValid()) {
                      vinos.add(
                        Vino(
                          id: const Uuid().v4(),
                          nombre: v.nombre.text,
                          descripcion: v.descripcion.text,
                          precio: double.tryParse(v.precio.text) ?? 0,
                          imagenUrl: v.imagenPath ?? '',
                        ),
                      );
                    }
                  }

                  await firestore.addVotacion(
                    _fecha!,
                    creador,
                    nombreController.text.trim(),
                    vinos,
                  );

                  Navigator.pop(context);
                },
                child: const Text('Crear votación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinoInput {
  final nombre = TextEditingController();
  final descripcion = TextEditingController();
  final precio = TextEditingController();
  String? imagenPath;

  bool showNombreError = false;
  bool showDescripcionError = false;
  bool showPrecioError = false;

  void validate() {
    showNombreError = nombre.text.trim().isEmpty;
    showDescripcionError = descripcion.text.trim().isEmpty;
    showPrecioError = double.tryParse(precio.text) == null;
  }

  bool isValid() =>
      !showNombreError && !showDescripcionError && !showPrecioError;

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nombre,
              decoration: InputDecoration(
                labelText: 'Nombre',
                errorText: showNombreError ? 'Campo obligatorio' : null,
              ),
            ),
            TextField(
              controller: descripcion,
              decoration: InputDecoration(
                labelText: 'Descripción',
                errorText: showDescripcionError ? 'Campo obligatorio' : null,
              ),
            ),
            TextField(
              controller: precio,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Precio (€)',
                errorText: showPrecioError
                    ? 'Introduce un número válido'
                    : null,
              ),
            ),
            // const SizedBox(height: 8),
            // ElevatedButton(
            //   onPressed: () async {
            //     final picker = ImagePicker();
            //     final picked = await picker.pickImage(
            //       source: ImageSource.camera,
            //     );
            //     if (picked != null) {
            //       imagenPath = picked.path;
            //       (context as Element).markNeedsBuild();
            //     }
            //   },
            //   child: const Text('Tomar imagen'),
            // ),
            if (imagenPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(
                  File(imagenPath!),
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
