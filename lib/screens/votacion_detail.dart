import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _VotacionDetailScreenState extends State<VotacionDetailScreen>
    with WidgetsBindingObserver {
  final Map<String, Voto> _votosPendientes = {};
  bool _isEnviando = false;
  bool _hayVotosEnviados = false;
  Set<String> _elementosConPosicionesRepetidas = {};

  /// Mismo Future en cada rebuild para que el FutureBuilder no reinicie la lista al hacer setState.
  Future<List<ElementoCata>>? _elementosFuture;
  bool _draftInicializado = false;
  String? _draftKey;

  String _buildDraftKey(String userId) {
    return 'votacion_draft_${widget.cata.id}_$userId';
  }

  Future<void> _guardarBorradorLocal() async {
    if (_draftKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      for (final entry in _votosPendientes.entries)
        entry.key: entry.value.toJson(),
    };
    await prefs.setString(_draftKey!, jsonEncode(payload));
  }

  Future<void> _limpiarBorradorLocal() async {
    if (_draftKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey!);
  }

  Future<void> _cargarBorradorLocal(String userId) async {
    final key = _buildDraftKey(userId);
    _draftKey = key;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final restaurados = <String, Voto>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map) {
          restaurados[entry.key] = Voto.fromJson(
            userId,
            Map<String, dynamic>.from(value),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _votosPendientes
          ..clear()
          ..addAll(restaurados);
        _detectarPosicionesRepetidas();
      });
    } catch (_) {
      // Si el borrador está corrupto, lo ignoramos sin bloquear la pantalla.
    }
  }

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

    // Validar que no haya puestos repetidos entre los votos que sí tienen posición
    final posiciones = _votosPendientes.values
        .map((v) => v.posicion)
        .where((pos) => pos != null)
        .cast<int>()
        .toList();
    final posicionesUnicas = posiciones.toSet();

    if (posiciones.length != posicionesUnicas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hay posiciones repetidas'),
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
        await _limpiarBorradorLocal();
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
    _guardarBorradorLocal();
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
    WidgetsBinding.instance.addObserver(this);
    _verificarVotosExistentes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _elementosFuture ??= Provider.of<FirestoreService>(
      context,
      listen: false,
    ).fetchElementosDeCata(widget.cata.id);

    if (!_draftInicializado) {
      _draftInicializado = true;
      final userId = Provider.of<AuthService>(
        context,
        listen: false,
      ).currentUser?.uid;
      if (userId != null) {
        _cargarBorradorLocal(userId);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _guardarBorradorLocal();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final tecladoAbierto = keyboardInset > 0;

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
      ),
      body: Stack(
        children: [
          FutureBuilder<List<ElementoCata>>(
            future: _elementosFuture,
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
                  16,
                  16,
                  tecladoAbierto
                      ? 24
                      : (cataCerrada ? 100 + bottomInset : 148 + bottomInset),
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
                    key: ValueKey(elemento.id),
                    votacionId: widget.cata.id,
                    elemento: elemento,
                    fechaCata: widget.cata.fecha,
                    userId: userId,
                    totalElementos: elementos.length,
                    votoInicial: _votosPendientes[elemento.id],
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

          // Barra inferior: cata abierta → Resultados + Guardar; cata cerrada → solo Resultados
          if (!tecladoAbierto)
            Positioned(
              bottom: 16 + bottomInset,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: cataCerrada
                    ? SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ResultadosScreen(votacionId: widget.cata.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('Ver resultados'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResultadosScreen(
                                      votacionId: widget.cata.id,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bar_chart),
                              label: const Text('Resultados'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
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
                                  : const Icon(Icons.save, color: Colors.white),
                              label: Text(
                                _isEnviando
                                    ? 'Guardando...'
                                    : 'Guardar (${_votosPendientes.length})',
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
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
