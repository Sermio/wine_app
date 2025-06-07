import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/votacion.dart';
import 'package:wine_app/models/vino.dart';
import 'package:wine_app/screens/resultados.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/screens/vote_form.dart';

class VotacionDetailScreen extends StatelessWidget {
  final Votacion votacion;
  const VotacionDetailScreen({super.key, required this.votacion});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la votación'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResultadosScreen(votacionId: votacion.id),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Vino>>(
        future: firestore.fetchVinosDeVotacion(votacion.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final vinos = snapshot.data!;
          return ListView.builder(
            itemCount: vinos.length,
            itemBuilder: (context, index) {
              final vino = vinos[index];
              return _VinoListItem(
                index: index,
                vino: vino,
                votacionId: votacion.id,
                userId: auth.currentUser!.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _VinoListItem extends StatefulWidget {
  final int index;
  final Vino vino;
  final String votacionId;
  final String userId;

  const _VinoListItem({
    required this.index,
    required this.vino,
    required this.votacionId,
    required this.userId,
  });

  @override
  State<_VinoListItem> createState() => _VinoListItemState();
}

class _VinoListItemState extends State<_VinoListItem> {
  bool mostrarNombre = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              mostrarNombre ? widget.vino.nombre : 'Vino ${widget.index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // IconButton(
          //   icon: Icon(
          //     mostrarNombre ? Icons.visibility_off : Icons.visibility,
          //     size: 20,
          //   ),
          //   onPressed: () {
          //     setState(() {
          //       mostrarNombre = !mostrarNombre;
          //     });
          //   },
          // ),
        ],
      ),
      subtitle: VoteForm(
        votacionId: widget.votacionId,
        vino: widget.vino,
        userId: widget.userId,
      ),
    );
  }
}
