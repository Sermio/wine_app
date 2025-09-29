import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/screens/resultados.dart';
import 'package:wine_app/screens/vote_form.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class VotacionDetailScreen extends StatelessWidget {
  final Cata cata;

  const VotacionDetailScreen({super.key, required this.cata});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Votaciones', style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: textColor),
            tooltip: 'Ver resultados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultadosScreen(votacionId: cata.id),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ElementoCata>>(
        future: firestore.fetchElementosDeCata(cata.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final elementos = snapshot.data!;
          elementos.sort(
            (a, b) => a.nombreAuxiliar.compareTo(b.nombreAuxiliar),
          );
          final userId = auth.currentUser!.uid;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ), // Padding inferior para evitar solapamiento
            itemCount: elementos.length,
            itemBuilder: (context, index) {
              final elemento = elementos[index];
              return _ElementoCataCard(
                index: index,
                elemento: elemento,
                votacionId: cata.id,
                userId: userId,
                fechaCata: cata.fecha,
              );
            },
          );
        },
      ),
    );
  }
}

class _ElementoCataCard extends StatefulWidget {
  final int index;
  final ElementoCata elemento;
  final String votacionId;
  final String userId;
  final DateTime fechaCata;

  const _ElementoCataCard({
    required this.index,
    required this.elemento,
    required this.votacionId,
    required this.userId,
    required this.fechaCata,
  });

  @override
  State<_ElementoCataCard> createState() => _ElementoCataCardState();
}

class _ElementoCataCardState extends State<_ElementoCataCard> {
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
            Center(
              child: Text(
                mostrarNombre
                    ? widget.elemento.nombre
                    : widget.elemento.nombreAuxiliar,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            VoteForm(
              votacionId: widget.votacionId,
              elemento: widget.elemento,
              fechaCata: widget.fechaCata,
              userId: widget.userId,
            ),
          ],
        ),
      ),
    );
  }
}
