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
  final Voto? votoInicial;
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
    this.votoInicial,
    this.onVoteChanged,
    this.cataCerrada = false,
    this.tienePosicionRepetida = false,
  });

  @override
  State<VoteForm> createState() => _VoteFormState();
}

class _VoteFormState extends State<VoteForm>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService firestore = FirestoreService();
  final TextEditingController comentarioController = TextEditingController();

  int? posicionSeleccionada;
  bool isLoading = false;
  Voto? votoExistente;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.votoInicial != null) {
      _aplicarVoto(widget.votoInicial!);
    } else {
      _cargarVotoExistente();
    }
  }

  @override
  void didUpdateWidget(covariant VoteForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nuevo = widget.votoInicial;
    final anterior = oldWidget.votoInicial;
    final cambioExterno =
        nuevo != null &&
        (anterior == null ||
            anterior.posicion != nuevo.posicion ||
            anterior.comentario != nuevo.comentario);
    if (cambioExterno) {
      _aplicarVoto(nuevo);
    }
  }

  void _aplicarVoto(Voto voto) {
    votoExistente = voto;
    posicionSeleccionada = voto.posicion;
    comentarioController.text = voto.comentario;
  }

  /// Sincroniza comentario y/o posición con el padre (permite solo comentario o solo voto).
  void _notificarCambio() {
    if (widget.onVoteChanged == null || widget.cataCerrada) return;
    final comentario = comentarioController.text.trim();
    final tienePosicion = posicionSeleccionada != null;
    final tieneComentario = comentario.isNotEmpty;
    if (!tienePosicion && !tieneComentario) {
      widget.onVoteChanged!(null);
      return;
    }
    widget.onVoteChanged!(
      Voto(
        usuarioId: widget.userId,
        posicion: posicionSeleccionada,
        comentario: comentario,
        esSistemaAntiguo: false,
      ),
    );
  }

  Future<void> _cargarVotoExistente() async {
    try {
      final votos = await firestore.fetchVotosDeElemento(
        widget.votacionId,
        widget.elemento.id,
      );
      final miVoto = votos[widget.userId];

      if (miVoto != null) {
        if (!mounted) return;
        setState(() {
          votoExistente = miVoto;
          posicionSeleccionada = miVoto.posicion;
          comentarioController.text = miVoto.comentario;
        });
        if (widget.onVoteChanged != null && !widget.cataCerrada) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onVoteChanged!(miVoto);
          });
        }
      }
    } catch (e) {
      print('Error cargando voto existente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  child: Text('$posicionº posición'),
                );
              }),
              onChanged: widget.cataCerrada
                  ? null
                  : (value) {
                      setState(() {
                        posicionSeleccionada = value;
                      });
                      _notificarCambio();
                    },
            ),
            const SizedBox(height: 16),

            // Campo de comentario
            TextField(
              controller: comentarioController,
              maxLines: 2,
              enabled: !widget.cataCerrada,
              onChanged: widget.cataCerrada ? null : (_) => _notificarCambio(),
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
      final antes = votoExistente!.posicion;
      final antesStr = antes != null ? '$antesº' : 'sin posición';
      return 'Cambio: $antesStr → $posicionSeleccionadaº posición';
    }
    return 'Posición asignada: $posicionSeleccionadaº posición';
  }
}
