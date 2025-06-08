import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/voto.dart';
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
  bool ordenarPorMedia = false;

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resultados', style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: Icon(
              ordenarPorMedia ? Icons.sort_by_alpha : Icons.sort,
              color: textColor,
            ),
            tooltip: 'Ordenar por media',
            onPressed: () {
              setState(() => ordenarPorMedia = !ordenarPorMedia);
            },
          ),
        ],
      ),
      body:
          FutureBuilder<
            (
              Map<String, Map<String, Voto>>, // elementoId → userId → Voto
              Map<String, String>, // elementoId → nombre
              Map<String, String>, // elementoId → nombreAuxiliar
              Map<String, double>, // elementoId → precio
            )
          >(
            future: firestore.fetchResultadosConNombres(widget.votacionId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final (votosPorElemento, nombres, nombresAux, precios) =
                  snapshot.data!;
              final elementoIds = votosPorElemento.keys.toList()
                ..sort((a, b) {
                  final auxA = nombresAux[a] ?? '';
                  final auxB = nombresAux[b] ?? '';
                  return auxA.compareTo(auxB);
                });

              final usuarios = <String>{};
              for (var votos in votosPorElemento.values) {
                usuarios.addAll(votos.keys);
              }

              return FutureBuilder<Map<String, String>>(
                future: firestore.fetchNombresUsuarios(usuarios),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final nombresUsuarios = userSnap.data!;
                  final usuarioList = usuarios.toList();

                  final medias = <String, double>{};
                  for (var elementoId in elementoIds) {
                    final puntuaciones = votosPorElemento[elementoId]!.values
                        .map((v) => v.puntuacion)
                        .toList();
                    medias[elementoId] = puntuaciones.isNotEmpty
                        ? puntuaciones.reduce((a, b) => a + b) /
                              puntuaciones.length
                        : 0;
                  }

                  final sortedElementoIds = [...elementoIds];
                  if (ordenarPorMedia) {
                    sortedElementoIds.sort(
                      (a, b) => medias[b]!.compareTo(medias[a]!),
                    );
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
                              mostrarNombres
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: textColor,
                            ),
                            label: Text(
                              mostrarNombres
                                  ? 'Ocultar nombres reales'
                                  : 'Mostrar nombres reales',
                              style: const TextStyle(color: textColor),
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
                      final votos = votosPorElemento[elementoId]!;
                      final media = medias[elementoId]!;

                      final nombreReal = nombres[elementoId] ?? 'Elemento';
                      final precio = precios[elementoId];
                      final nombreAux = nombresAux[elementoId] ?? 'Elemento';

                      final nombreMostrar = mostrarNombres
                          ? '$nombreReal ${precio != null ? '(${precio.toStringAsFixed(2)}€)' : ''}'
                          : nombreAux;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreMostrar,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Media: ${media.toStringAsFixed(1)} / 10',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              ...usuarioList.map((uid) {
                                final voto = votos[uid];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        nombresUsuarios[uid] ?? uid,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        voto != null
                                            ? voto.puntuacion.toStringAsFixed(1)
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
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }
}
