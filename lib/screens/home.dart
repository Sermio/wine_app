import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/votacion.dart';
import 'package:wine_app/screens/create_votacion.dart';
import 'package:wine_app/screens/login.dart';
import 'package:wine_app/screens/votacion_detail.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: StreamBuilder<List<Votacion>>(
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: catas.length,
            itemBuilder: (context, index) {
              final votacion = catas[index];
              final fechaHoy = DateTime(ahora.year, ahora.month, ahora.day);
              final fechaVotacion = DateTime(
                votacion.fecha.year,
                votacion.fecha.month,
                votacion.fecha.day,
              );
              final esPasada = fechaVotacion.isBefore(fechaHoy);

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
                    votacion.nombre,
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
                        'Fecha: ${votacion.fecha.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esPasada ? 'Votación finalizada' : 'Votación en curso',
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
                        builder: (_) =>
                            VotacionDetailScreen(votacion: votacion),
                      ),
                    );
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateVotacionScreen()),
          );
        },
        child: const Icon(Icons.add, color: textColor),
      ),
    );
  }
}
