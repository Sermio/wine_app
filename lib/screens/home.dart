import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/screens/create_cata.dart';
import 'package:wine_app/screens/login.dart';
import 'package:wine_app/screens/votacion_detail.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> confirmarYBorrarCata(
    BuildContext context,
    FirestoreService firestore,
    Cata cata,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            'Eliminar cata',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Text('¿Quieres eliminar la cata "${cata.nombre}"?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await firestore.deleteCata(cata.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cata "${cata.nombre}" eliminada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Catas', style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            color: textColor,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Cata>>(
        stream: firestore.streamCatas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay catas aún.'));
          }

          final catas = snapshot.data!;
          final ahora = DateTime.now();
          final hoy = DateTime(ahora.year, ahora.month, ahora.day);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: catas.length,
            itemBuilder: (context, index) {
              final cata = catas[index];
              final fechaCata = DateTime(
                cata.fecha.year,
                cata.fecha.month,
                cata.fecha.day,
              );
              final esPasada = fechaCata.isBefore(hoy);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: esPasada ? Colors.grey[100] : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: esPasada ? Colors.grey[400] : primaryColor,
                    child: Icon(
                      esPasada ? Icons.history : Icons.event_available,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    cata.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${cata.fecha.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esPasada ? 'Cata finalizada' : 'Cata en curso',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: esPasada ? Colors.red[400] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VotacionDetailScreen(cata: cata),
                      ),
                    );
                  },
                  onLongPress: () {
                    confirmarYBorrarCata(context, firestore, cata);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateCataScreen()));
        },
        child: const Icon(Icons.add, color: textColor),
      ),
    );
  }
}
