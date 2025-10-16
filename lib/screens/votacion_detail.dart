import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/screens/resultados.dart';
import 'package:wine_app/screens/vote_form.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class VotacionDetailScreen extends StatefulWidget {
  final Cata cata;

  const VotacionDetailScreen({super.key, required this.cata});

  @override
  State<VotacionDetailScreen> createState() => _VotacionDetailScreenState();
}

class _VotacionDetailScreenState extends State<VotacionDetailScreen> {
  final Map<String, Voto> _votosPendientes = {};
  bool _isEnviando = false;
  bool _hayVotosEnviados = false;
  Set<String> _elementosConPosicionesRepetidas = {};

  void _enviarTodasLasVotaciones(BuildContext context) async {
    if (_votosPendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay votaciones para enviar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que no haya puestos repetidos SOLO en los votos pendientes
    final posiciones = _votosPendientes.values
        .map((v) => v.posicion)
        .where((pos) => pos != null)
        .cast<int>()
        .toList();
    final posicionesUnicas = posiciones.toSet();

    if (posiciones.length != posicionesUnicas.length) {
      // Encontrar posiciones repetidas
      final posicionesRepetidas = <int>[];
      final posicionesContadas = <int, int>{};

      for (final posicion in posiciones) {
        posicionesContadas[posicion] = (posicionesContadas[posicion] ?? 0) + 1;
      }

      for (final entry in posicionesContadas.entries) {
        if (entry.value > 1) {
          posicionesRepetidas.add(entry.key);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hay posiciones repetidas'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Validar que todas las posiciones estén asignadas (1 a N)
    final totalElementos = _votosPendientes.length;
    final posicionesEsperadas = List.generate(
      totalElementos,
      (index) => index + 1,
    );
    final posicionesAsignadas = posiciones.toSet();

    if (!posicionesEsperadas.every(
      (pos) => posicionesAsignadas.contains(pos),
    )) {
      // Encontrar posiciones faltantes
      final posicionesFaltantes = posicionesEsperadas
          .where((pos) => !posicionesAsignadas.contains(pos))
          .toList();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan posiciones por asignar'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => _isEnviando = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser!.uid;

      // Enviar todas las votaciones
      for (var entry in _votosPendientes.entries) {
        final elementoId = entry.key;
        final voto = entry.value;

        await firestore.addOrUpdateVoto(
          widget.cata.id,
          elementoId,
          userId,
          voto,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hayVotosEnviados
                  ? 'Votaciones actualizadas correctamente'
                  : 'Todas las votaciones han sido enviadas correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar votos pendientes y marcar que hay votos enviados
        setState(() {
          _votosPendientes.clear();
          _hayVotosEnviados = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar votaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isEnviando = false);
    }
  }

  void _onVoteChanged(String elementoId, Voto? voto) {
    setState(() {
      if (voto != null) {
        _votosPendientes[elementoId] = voto;
      } else {
        _votosPendientes.remove(elementoId);
      }
      _detectarPosicionesRepetidas();
    });
  }

  void _detectarPosicionesRepetidas() {
    final posiciones = _votosPendientes.values
        .map((v) => v.posicion)
        .where((pos) => pos != null)
        .cast<int>()
        .toList();

    final posicionesContadas = <int, int>{};
    for (final posicion in posiciones) {
      posicionesContadas[posicion] = (posicionesContadas[posicion] ?? 0) + 1;
    }

    final posicionesRepetidas = posicionesContadas.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toSet();

    _elementosConPosicionesRepetidas.clear();

    for (final entry in _votosPendientes.entries) {
      final elementoId = entry.key;
      final voto = entry.value;
      if (voto.posicion != null &&
          posicionesRepetidas.contains(voto.posicion)) {
        _elementosConPosicionesRepetidas.add(elementoId);
      }
    }
  }

  Future<void> _verificarVotosExistentes() async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser!.uid;

      // Verificar si ya hay votos para esta cata
      final elementos = await firestore.fetchElementosDeCata(widget.cata.id);
      bool hayVotos = false;

      for (var elemento in elementos) {
        final votos = await firestore.fetchVotosDeElemento(
          widget.cata.id,
          elemento.id,
        );
        if (votos.containsKey(userId)) {
          hayVotos = true;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _hayVotosEnviados = hayVotos;
        });
      }
    } catch (e) {
      print('Error verificando votos existentes: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarVotosExistentes();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    // Verificar si la cata está cerrada
    final ahora = DateTime.now();
    final fechaCata = widget.cata.fecha;
    // La cata está cerrada si la fecha actual es posterior al final del día de la cata
    final finDelDiaCata = DateTime(
      fechaCata.year,
      fechaCata.month,
      fechaCata.day,
      23,
      59,
      59,
    );
    final cataCerrada = ahora.isAfter(finDelDiaCata);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Votaciones', style: appBarTitleStyle),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: shadowColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver resultados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultadosScreen(votacionId: widget.cata.id),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<ElementoCata>>(
            future: firestore.fetchElementosDeCata(widget.cata.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final elementos = snapshot.data!;
              elementos.sort(
                (a, b) => a.nombreAuxiliar.compareTo(b.nombreAuxiliar),
              );
              final userId = auth.currentUser!.uid;

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  cataCerrada ? 16 : 80, // Menos margen si la cata está cerrada
                  16,
                  cataCerrada
                      ? 16
                      : 100, // Menos padding si la cata está cerrada
                ),
                itemCount:
                    elementos.length +
                    (cataCerrada ? 1 : 0), // +1 para el mensaje de cata cerrada
                itemBuilder: (context, index) {
                  // Mostrar mensaje de cata cerrada al principio
                  if (cataCerrada && index == 0) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.red[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cata cerrada',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Esta cata ya ha finalizado. No se pueden realizar más votaciones.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Ajustar índice si hay mensaje de cata cerrada
                  final elementoIndex = cataCerrada ? index - 1 : index;
                  final elemento = elementos[elementoIndex];

                  return VoteForm(
                    votacionId: widget.cata.id,
                    elemento: elemento,
                    fechaCata: widget.cata.fecha,
                    userId: userId,
                    totalElementos: elementos.length,
                    cataCerrada: cataCerrada,
                    tienePosicionRepetida: _elementosConPosicionesRepetidas
                        .contains(elemento.id),
                    onVoteChanged: cataCerrada
                        ? null
                        : (voto) {
                            // Deshabilitar votaciones si está cerrada
                            _onVoteChanged(elemento.id, voto);
                          },
                  );
                },
              );
            },
          ),

          // Botón flotante fijo para enviar todas las votaciones (solo si la cata no está cerrada)
          if (!cataCerrada)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isEnviando
                      ? null
                      : () {
                          _enviarTodasLasVotaciones(context);
                        },
                  icon: _isEnviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isEnviando
                        ? 'Enviando...'
                        : _hayVotosEnviados
                        ? 'Actualizar votaciones (${_votosPendientes.length})'
                        : 'Enviar todas las votaciones (${_votosPendientes.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
