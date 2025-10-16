import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/screens/resultados_detail.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class ResultadosScreen extends StatefulWidget {
  final String votacionId;
  const ResultadosScreen({super.key, required this.votacionId});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  bool mostrarNombres = false;
  bool ordenarPorMedia = true;
  bool _isLoading = true;
  Map<String, Map<String, Voto>>? _votosPorElemento;
  Map<String, String>? _nombres;
  Map<String, String>? _descripciones;
  Map<String, String>? _nombresAux;
  Map<String, double>? _precios;
  Map<String, String>? _imagenes;
  Map<String, String>? _nombresUsuarios;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    try {
      // Cargar datos de resultados
      final (
        votosPorElemento,
        nombres,
        descripciones,
        nombresAux,
        precios,
        imagenes,
      ) = await firestore.fetchResultadosConNombres(
        widget.votacionId,
      );

      // Obtener usuarios únicos
      final usuarios = <String>{};
      for (var votos in votosPorElemento.values) {
        usuarios.addAll(votos.keys);
      }

      // Cargar nombres de usuarios
      final nombresUsuarios = await firestore.fetchNombresUsuarios(usuarios);

      if (mounted) {
        setState(() {
          _votosPorElemento = votosPorElemento;
          _nombres = nombres;
          _descripciones = descripciones;
          _nombresAux = nombresAux;
          _precios = precios;
          _imagenes = imagenes;
          _nombresUsuarios = nombresUsuarios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error al cargar datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resultados', style: appBarTitleStyle),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: shadowColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(ordenarPorMedia ? Icons.sort_by_alpha : Icons.sort),
            tooltip: ordenarPorMedia
                ? 'Ordenar por ranking'
                : 'Ordenar por posición original',
            onPressed: () {
              setState(() => ordenarPorMedia = !ordenarPorMedia);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_votosPorElemento == null || _nombresUsuarios == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar resultados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final elementoIds = _votosPorElemento!.keys.toList()
      ..sort((a, b) {
        final auxA = _nombresAux![a] ?? '';
        final auxB = _nombresAux![b] ?? '';
        return auxA.compareTo(auxB);
      });

    final usuarios = <String>{};
    for (var votos in _votosPorElemento!.values) {
      usuarios.addAll(votos.keys);
    }

    final usuarioList = usuarios.toList();

    final sumas = <String, double>{};
    final esSistemaAntiguo = <String, bool>{};

    for (var elementoId in elementoIds) {
      final votos = _votosPorElemento![elementoId]!.values.toList();

      if (votos.isNotEmpty && votos.first.esSistemaAntiguo) {
        // Sistema antiguo: sumar puntuaciones (mayor suma = mejor)
        final puntuaciones = votos.map((v) => v.puntuacion!).toList();
        sumas[elementoId] = puntuaciones.reduce((a, b) => a + b);
        esSistemaAntiguo[elementoId] = true;
      } else {
        // Sistema nuevo: sumar posiciones (menor suma = mejor)
        final posiciones = votos.map((v) => v.posicion!).toList();
        sumas[elementoId] = posiciones.isNotEmpty
            ? posiciones.reduce((a, b) => a + b).toDouble()
            : 0.0;
        esSistemaAntiguo[elementoId] = false;
      }
    }

    final sortedElementoIds = [...elementoIds];
    if (ordenarPorMedia) {
      // Verificar si todos los elementos usan el mismo sistema
      final todosAntiguos = esSistemaAntiguo.values.every((es) => es);
      final todosNuevos = esSistemaAntiguo.values.every((es) => !es);

      if (todosAntiguos) {
        // Sistema antiguo: ordenar por suma descendente (mayor suma = mejor)
        sortedElementoIds.sort((a, b) => sumas[b]!.compareTo(sumas[a]!));
      } else if (todosNuevos) {
        // Sistema nuevo: ordenar por suma ascendente (menor suma = mejor)
        sortedElementoIds.sort((a, b) => sumas[a]!.compareTo(sumas[b]!));
      } else {
        // Sistema mixto: usar sistema nuevo por defecto
        sortedElementoIds.sort((a, b) => sumas[a]!.compareTo(sumas[b]!));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedElementoIds.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                mostrarNombres ? Icons.visibility_off : Icons.visibility,
                color: Colors.white,
              ),
              label: Text(
                mostrarNombres
                    ? 'Ocultar nombres reales'
                    : 'Mostrar nombres reales',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  mostrarNombres = !mostrarNombres;
                });
              },
            ),
          );
        }

        final realIndex = index - 1;
        final elementoId = sortedElementoIds[realIndex];
        final votos = _votosPorElemento![elementoId]!;
        final suma = sumas[elementoId]!;

        final nombreReal = _nombres![elementoId] ?? 'Elemento';
        final descripcion = _descripciones![elementoId] ?? '';
        final precio = _precios![elementoId];
        final nombreAux = _nombresAux![elementoId] ?? 'Elemento';
        final imagenUrl = _imagenes![elementoId] ?? '';

        final nombreMostrar = mostrarNombres
            ? '$nombreReal ${precio != null ? '(${precio.toStringAsFixed(2)}€)' : ''}'
            : nombreAux;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ElementoDetalleScreen(
                  votacionId: widget.votacionId,
                  elementoId: elementoId,
                  nombre: nombreReal,
                  precio: precio,
                  descripcion: descripcion,
                  imagenUrl: imagenUrl,
                ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    nombreMostrar,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${realIndex + 1}º puesto ($suma)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...usuarioList.isEmpty
                      ? [
                          const Text(
                            'Sin votos de usuarios',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]
                      : List.generate(usuarioList.length * 2 - 1, (i) {
                          if (i.isOdd) {
                            return const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.grey,
                            );
                          }

                          final index = i ~/ 2;
                          final uid = usuarioList[index];
                          final voto = votos[uid];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _nombresUsuarios![uid] ?? uid,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  voto != null
                                      ? (voto.esSistemaAntiguo
                                            ? '${voto.puntuacion!.toStringAsFixed(1)}'
                                            : '${voto.posicion}º')
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
