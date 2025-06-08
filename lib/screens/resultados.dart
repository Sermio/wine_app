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
          FutureBuilder<(Map<String, Map<String, Voto>>, Map<String, String>)>(
            future: firestore.fetchResultados(widget.votacionId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final (data, nombresCata) = snapshot.data!;
              final catas = data.keys.toList();
              final usuarios = <String>{};
              for (var votos in data.values) {
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
                  for (var cataId in catas) {
                    final votos = data[cataId]!.values
                        .map((v) => v.puntuacion)
                        .toList();
                    medias[cataId] = votos.isNotEmpty
                        ? votos.reduce((a, b) => a + b) / votos.length
                        : 0;
                  }

                  // Asociar nombres temporales consistentes por ID
                  final nombresGenericos = <String, String>{};
                  int contador = 1;
                  for (final cataId in catas) {
                    nombresGenericos[cataId] = 'Cata $contador';
                    contador++;
                  }

                  final sortedCataIds = [...catas];
                  if (ordenarPorMedia) {
                    sortedCataIds.sort(
                      (a, b) => medias[b]!.compareTo(medias[a]!),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedCataIds.length + 1,
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
                                  ? 'Ocultar nombres de catas'
                                  : 'Mostrar nombres de catas',
                              style: TextStyle(color: textColor),
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
                      final cataId = sortedCataIds[realIndex];
                      final votos = data[cataId]!;
                      final media = medias[cataId]!;
                      final nombreCata = mostrarNombres
                          ? (nombresCata[cataId] ?? nombresGenericos[cataId]!)
                          : nombresGenericos[cataId]!;

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
                                nombreCata,
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
