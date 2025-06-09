import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/voto.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class ElementoDetalleScreen extends StatelessWidget {
  final String votacionId;
  final String elementoId;
  final String nombre;
  final double? precio;
  final String imagenUrl;
  final String descripcion;

  const ElementoDetalleScreen({
    super.key,
    required this.votacionId,
    required this.elementoId,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, Voto>>(
        future: firestore.fetchVotosDeElemento(votacionId, elementoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Sin votos disponibles'));
          }

          final votos = snapshot.data!;
          final usuarios = votos.keys.toList();

          return FutureBuilder<Map<String, String>>(
            future: firestore.fetchNombresUsuarios(usuarios.toSet()),
            builder: (context, nombresSnap) {
              if (nombresSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!nombresSnap.hasData) {
                return const Center(child: Text('Error al cargar nombres'));
              }

              final nombresUsuarios = nombresSnap.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (imagenUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.black,
                              insetPadding: const EdgeInsets.all(16),
                              child: Stack(
                                children: [
                                  InteractiveViewer(
                                    panEnabled: true,
                                    minScale: 1,
                                    maxScale: 5,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(imagenUrl),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: textColor,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imagenUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (precio != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Precio: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${precio!.toStringAsFixed(2)} €',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Descripción: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: descripcion,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    const Text(
                      'Votos:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...votos.entries.map((entry) {
                      final uid = entry.key;
                      final voto = entry.value;
                      return SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombresUsuarios[uid] ?? uid,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nota: ${voto.puntuacion.toStringAsFixed(1)}',
                                ),
                                if (voto.comentario.trim().isNotEmpty)
                                  Text('Comentario: ${voto.comentario}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
