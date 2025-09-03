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
        title: Text(nombre, style: appBarTitleStyle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shadowColor: shadowColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
                        onTap: () => _showImageModal(context, imagenUrl),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 200,
                            maxHeight: 300,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radiusM),
                            child: Image.network(
                              imagenUrl,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text('Error al cargar la imagen'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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

  void _showImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isWeb = screenSize.width > 768;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: isWeb
              ? const EdgeInsets.all(40)
              : const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radiusM),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: elevationL,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(spacingM),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vista previa de imagen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            tooltip: 'Cerrar',
                          ),
                        ],
                      ),
                      const SizedBox(height: spacingM),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: isWeb
                              ? screenSize.height * 0.7
                              : screenSize.height * 0.6,
                          maxWidth: isWeb
                              ? screenSize.width * 0.8
                              : screenSize.width * 0.9,
                        ),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: isWeb ? 5.0 : 3.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radiusS),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text('Error al cargar la imagen'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: spacingM),
                      Text(
                        isWeb
                            ? 'Usa la rueda del ratón o Ctrl + scroll para hacer zoom'
                            : 'Pellizca para hacer zoom',
                        style: bodySmallStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
