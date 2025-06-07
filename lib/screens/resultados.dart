import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/services/firestore_service.dart';

class ResultadosScreen extends StatefulWidget {
  final String votacionId;
  const ResultadosScreen({super.key, required this.votacionId});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  late Map<String, bool> mostrarNombres;

  @override
  void initState() {
    super.initState();
    mostrarNombres = {};
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body:
          FutureBuilder<(Map<String, Map<String, Voto>>, Map<String, String>)>(
            future: firestore.fetchResultados(widget.votacionId),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final (data, nombresVino) = snapshot.data!;
              final vinos = data.keys.toList();
              final usuarios = <String>{};
              for (var votos in data.values) {
                usuarios.addAll(votos.keys);
              }

              for (var vinoId in vinos) {
                mostrarNombres.putIfAbsent(vinoId, () => false);
              }

              return FutureBuilder<Map<String, String>>(
                future: firestore.fetchNombresUsuarios(usuarios),
                builder: (context, userSnap) {
                  if (!userSnap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final nombresUsuarios = userSnap.data!;
                  final usuarioList = usuarios.toList();

                  final medias = <String, double>{};
                  for (var vinoId in vinos) {
                    final votos = data[vinoId]!.values
                        .map((v) => v.puntuacion)
                        .toList();
                    if (votos.isNotEmpty) {
                      medias[vinoId] =
                          votos.reduce((a, b) => a + b) / votos.length;
                    } else {
                      medias[vinoId] = 0;
                    }
                  }

                  final maxMedia = medias.values.reduce(
                    (a, b) => a > b ? a : b,
                  );
                  final minMedia = medias.values.reduce(
                    (a, b) => a < b ? a : b,
                  );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Usuario')),
                        ...vinos.map(
                          (vinoId) => DataColumn(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mostrarNombres[vinoId]!
                                      ? nombresVino[vinoId] ?? 'Sin nombre'
                                      : 'Vino ${vinos.indexOf(vinoId) + 1}',
                                ),
                                IconButton(
                                  icon: Icon(
                                    mostrarNombres[vinoId]!
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      mostrarNombres[vinoId] =
                                          !mostrarNombres[vinoId]!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      rows: [
                        ...usuarioList.map((uid) {
                          return DataRow(
                            cells: [
                              DataCell(Text(nombresUsuarios[uid] ?? uid)),
                              ...vinos.map((vinoId) {
                                final voto = data[vinoId]?[uid];
                                return DataCell(
                                  Text(
                                    voto != null
                                        ? voto.puntuacion.toString()
                                        : '-',
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                        DataRow(
                          color: WidgetStateProperty.all(Colors.white),
                          cells: [
                            const DataCell(
                              Text(
                                'Media',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...vinos.map((vinoId) {
                              final media = medias[vinoId]!;
                              Color? color;
                              if (media == maxMedia) {
                                color = Colors.green[300];
                              } else if (media == minMedia) {
                                color = Colors.red[300];
                              }
                              return DataCell(
                                Container(
                                  color: color,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    media.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
