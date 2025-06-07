import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/votacion.dart';
import 'package:wine_app/screens/create_votacion.dart';
import 'package:wine_app/screens/login.dart';
import 'package:wine_app/screens/votacion_detail.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catas'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
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
      body: FutureBuilder<List<Votacion>>(
        future: firestore.fetchVotaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay votaciones aún.'));
          }

          final votaciones = snapshot.data!;
          final ahora = DateTime.now();

          return ListView.builder(
            itemCount: votaciones.length,
            itemBuilder: (context, index) {
              final votacion = votaciones[index];
              final fechaHoy = DateTime(ahora.year, ahora.month, ahora.day);
              final fechaVotacion = DateTime(
                votacion.fecha.year,
                votacion.fecha.month,
                votacion.fecha.day,
              );
              final esPasada = fechaVotacion.isBefore(fechaHoy);

              return Card(
                color: esPasada ? Colors.yellow[100] : Colors.green[100],
                child: ListTile(
                  title: Text(
                    'Votación del ${votacion.fecha.toLocal().toString().split(' ')[0]}',
                  ),
                  subtitle: Text(votacion.nombre),
                  // Text(
                  //   esPasada ? 'Votación pasada' : 'Votación activa',
                  // ),
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
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateVotacionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
