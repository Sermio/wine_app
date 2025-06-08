import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/votacion.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/screens/resultados.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/screens/vote_form.dart';
import 'package:wine_app/utils/styles.dart';

class VotacionDetailScreen extends StatelessWidget {
  final Votacion votacion;

  const VotacionDetailScreen({super.key, required this.votacion});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detalles de la votación',
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        actions: [
          IconButton(
            color: textColor,
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver resultados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultadosScreen(votacionId: votacion.id),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Cata>>(
        future: firestore.fetchCatasDeVotacion(votacion.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final catas = snapshot.data!;
          return SafeArea(
            top: false,
            bottom: true,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: catas.length,
              itemBuilder: (context, index) {
                final cata = catas[index];
                return _CataCard(
                  index: index,
                  cata: cata,
                  votacionId: votacion.id,
                  userId: auth.currentUser!.uid,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CataCard extends StatefulWidget {
  final int index;
  final Cata cata;
  final String votacionId;
  final String userId;

  const _CataCard({
    required this.index,
    required this.cata,
    required this.votacionId,
    required this.userId,
  });

  @override
  State<_CataCard> createState() => _CataCardState();
}

class _CataCardState extends State<_CataCard> {
  bool mostrarNombre = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mostrarNombre
                      ? widget.cata.nombre
                      : 'Cata ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                // Puedes habilitar esto si quieres permitir mostrar el nombre real:
                // IconButton(
                //   icon: Icon(
                //     mostrarNombre ? Icons.visibility_off : Icons.visibility,
                //     size: 20,
                //     color: Colors.grey,
                //   ),
                //   onPressed: () {
                //     setState(() => mostrarNombre = !mostrarNombre);
                //   },
                // ),
              ],
            ),
            const SizedBox(height: 8),
            VoteForm(
              votacionId: widget.votacionId,
              cata: widget.cata,
              userId: widget.userId,
            ),
            // SizedBox(height: 400),
          ],
        ),
      ),
    );
  }
}
