import 'package:flutter/material.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/services/firestore_service.dart';

class VoteForm extends StatefulWidget {
  final String votacionId;
  final ElementoCata elemento;
  final DateTime fechaCata;
  final String userId;
  final int totalElementos;
  final Function(Voto?)? onVoteChanged;
  final bool cataCerrada;
  final bool tienePosicionRepetida;

  const VoteForm({
    super.key,
    required this.votacionId,
    required this.elemento,
    required this.fechaCata,
    required this.userId,
    required this.totalElementos,
    this.onVoteChanged,
    this.cataCerrada = false,
    this.tienePosicionRepetida = false,
  });

  @override
  State<VoteForm> createState() => _VoteFormState();
}

class _VoteFormState extends State<VoteForm> {
  final FirestoreService firestore = FirestoreService();
  final TextEditingController comentarioController = TextEditingController();

  int? posicionSeleccionada;
  bool isLoading = false;
  Voto? votoExistente;

  @override
  void initState() {
    super.initState();
    _cargarVotoExistente();
  }

  Future<void> _cargarVotoExistente() async {
    try {
      final votos = await firestore.fetchVotosDeElemento(
        widget.votacionId,
        widget.elemento.id,
      );
      final miVoto = votos[widget.userId];

      if (miVoto != null) {
        setState(() {
          votoExistente = miVoto;
          posicionSeleccionada = miVoto.posicion;
          comentarioController.text = miVoto.comentario;
        });
      }
    } catch (e) {
      print('Error cargando voto existente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.elemento.nombreAuxiliar,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Selector de posición (reemplaza el slider original)
            Text(
              'Selecciona la posición:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              value: posicionSeleccionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.tienePosicionRepetida
                        ? Colors.red
                        : Colors.grey,
                    width: widget.tienePosicionRepetida ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.tienePosicionRepetida
                        ? Colors.red
                        : Colors.grey,
                    width: widget.tienePosicionRepetida ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.tienePosicionRepetida
                        ? Colors.red
                        : Colors.blue,
                    width: widget.tienePosicionRepetida ? 2 : 2,
                  ),
                ),
                filled: true,
                fillColor: widget.cataCerrada ? Colors.grey[200] : Colors.white,
              ),
              dropdownColor: Colors.white,
              style: TextStyle(
                color: widget.cataCerrada ? Colors.grey[600] : Colors.black,
              ),
              hint: Text(
                widget.cataCerrada ? 'Cata cerrada' : 'Selecciona posición',
                style: TextStyle(
                  color: widget.cataCerrada ? Colors.grey[600] : null,
                ),
              ),
              items: List.generate(widget.totalElementos, (index) {
                final posicion = index + 1;
                return DropdownMenuItem<int>(
                  value: posicion,
                  child: Text('$posicionº lugar'),
                );
              }),
              onChanged: widget.cataCerrada
                  ? null
                  : (value) {
                      setState(() {
                        posicionSeleccionada = value;
                      });

                      // Notificar cambio al padre
                      if (widget.onVoteChanged != null) {
                        if (value != null) {
                          final voto = Voto(
                            usuarioId: widget.userId,
                            posicion: value,
                            comentario: comentarioController.text.trim(),
                            esSistemaAntiguo: false,
                          );
                          widget.onVoteChanged!(voto);
                        } else {
                          widget.onVoteChanged!(null);
                        }
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Campo de comentario
            TextField(
              controller: comentarioController,
              maxLines: 2,
              enabled: !widget.cataCerrada,
              onChanged: widget.cataCerrada
                  ? null
                  : (value) {
                      // Actualizar voto si ya hay posición seleccionada
                      if (posicionSeleccionada != null &&
                          widget.onVoteChanged != null) {
                        final voto = Voto(
                          usuarioId: widget.userId,
                          posicion: posicionSeleccionada!,
                          comentario: value.trim(),
                          esSistemaAntiguo: false,
                        );
                        widget.onVoteChanged!(voto);
                      }
                    },
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: widget.cataCerrada
                    ? Colors.grey[200]
                    : Colors.grey[50],
              ),
            ),

            // Indicador de voto guardado o posición actual
            if (posicionSeleccionada != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getIndicadorColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIndicadorIcon(),
                      color: _getIndicadorTextColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getIndicadorTexto(),
                      style: TextStyle(
                        color: _getIndicadorTextColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  // Métodos helper para el indicador visual
  Color _getIndicadorColor() {
    if (votoExistente != null &&
        votoExistente!.posicion != posicionSeleccionada) {
      return Colors.orange[100]!; // Amarillo/naranja para cambio
    }
    return Colors.green[100]!; // Verde para posición actual
  }

  Color _getIndicadorTextColor() {
    if (votoExistente != null &&
        votoExistente!.posicion != posicionSeleccionada) {
      return Colors.orange[700]!; // Amarillo/naranja para cambio
    }
    return Colors.green[700]!; // Verde para posición actual
  }

  IconData _getIndicadorIcon() {
    if (votoExistente != null &&
        votoExistente!.posicion != posicionSeleccionada) {
      return Icons.warning; // Icono de advertencia para cambio
    }
    return Icons.check_circle; // Check para posición actual
  }

  String _getIndicadorTexto() {
    if (votoExistente != null &&
        votoExistente!.posicion != posicionSeleccionada) {
      return 'Cambio: ${votoExistente!.posicion}º → ${posicionSeleccionada}º lugar';
    }
    return 'Posición asignada: ${posicionSeleccionada}º lugar';
  }
}
