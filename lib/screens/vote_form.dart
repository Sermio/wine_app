import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/vino.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/services/firestore_service.dart';

class VoteForm extends StatefulWidget {
  final String votacionId;
  final Vino vino;
  final String userId;
  const VoteForm({
    super.key,
    required this.votacionId,
    required this.vino,
    required this.userId,
  });

  @override
  State<VoteForm> createState() => _VoteFormState();
}

class _VoteFormState extends State<VoteForm> {
  final comentario = TextEditingController();
  int puntuacion = 5;

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    return Column(
      children: [
        Slider(
          value: puntuacion.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: puntuacion.toString(),
          onChanged: (val) => setState(() => puntuacion = val.round()),
        ),
        TextField(
          controller: comentario,
          decoration: const InputDecoration(labelText: 'Comentario'),
        ),
        ElevatedButton(
          onPressed: () async {
            final voto = Voto(
              usuarioId: widget.userId,
              puntuacion: puntuacion,
              comentario: comentario.text,
            );
            await firestore.addOrUpdateVoto(
              widget.votacionId,
              widget.vino.id,
              widget.userId,
              voto,
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Voto registrado')));
          },
          child: const Text('Votar'),
        ),
      ],
    );
  }
}
