import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class VoteForm extends StatefulWidget {
  final String votacionId;
  final Cata cata;
  final String userId;

  const VoteForm({
    super.key,
    required this.votacionId,
    required this.cata,
    required this.userId,
  });

  @override
  State<VoteForm> createState() => _VoteFormState();
}

class _VoteFormState extends State<VoteForm> {
  final comentario = TextEditingController();
  double puntuacion = 5.0;
  bool votoRegistrado = false;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVoto();
  }

  Future<void> _cargarVoto() async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final voto = await firestore.getVotoUsuario(
      widget.votacionId,
      widget.cata.id,
      widget.userId,
    );

    if (voto != null) {
      puntuacion = voto.puntuacion;
      comentario.text = voto.comentario;
      votoRegistrado = true;
    }

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: puntuacion,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                label: puntuacion.toStringAsFixed(1),
                activeColor: primaryColor,
                inactiveColor: primaryColor.withOpacity(0.3),
                onChanged: (val) => setState(() => puntuacion = val),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${puntuacion.toStringAsFixed(1)}/10',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: comentario,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Comentario',
            labelStyle: TextStyle(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final voto = Voto(
                usuarioId: widget.userId,
                puntuacion: puntuacion,
                comentario: comentario.text,
              );
              await firestore.addOrUpdateVoto(
                widget.votacionId,
                widget.cata.id,
                widget.userId,
                voto,
              );
              final yaHabiaVotado = votoRegistrado;
              setState(() => votoRegistrado = true);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      yaHabiaVotado
                          ? 'Has actualizado tu voto'
                          : 'Voto registrado',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Votar', style: TextStyle(color: textColor)),
                if (votoRegistrado) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, color: textColor),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
