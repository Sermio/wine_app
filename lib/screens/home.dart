import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/screens/create_cata.dart';
import 'package:wine_app/screens/votacion_detail.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cerrandoSesion = false;

  Future<void> _mostrarOpcionesCata(
    BuildContext context,
    FirestoreService firestore,
    Cata cata,
  ) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar cata'),
              onTap: () => Navigator.of(ctx).pop('editar'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar cata'),
              onTap: () => Navigator.of(ctx).pop('eliminar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (accion == 'editar') {
      if (!context.mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => CreateCataScreen(cata: cata)));
      return;
    }

    if (accion == 'eliminar') {
      if (!context.mounted) return;
      await confirmarYBorrarCata(context, firestore, cata);
    }
  }

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
        title: const Text('Catas', style: appBarTitleStyle),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: shadowColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrandoSesion
                ? null
                : () async {
                    setState(() => _cerrandoSesion = true);
                    // Espera a que se reconstruya sin StreamBuilder antes del signOut.
                    await WidgetsBinding.instance.endOfFrame;
                    await auth.signOut();
                    if (!mounted) return;
                    setState(() => _cerrandoSesion = false);
                  },
          ),
        ],
      ),
      body: _cerrandoSesion
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Cata>>(
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
                final bottomInset = MediaQuery.of(context).padding.bottom;

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 104 + bottomInset),
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
                          backgroundColor: esPasada
                              ? Colors.grey[400]
                              : primaryColor,
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
                                color: esPasada
                                    ? Colors.red[400]
                                    : Colors.green[700],
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
                          _mostrarOpcionesCata(context, firestore, cata);
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
