import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wine_app/models/votacion.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/voto.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Votacion>> streamCatas() {
    return _db
        .collection('catas')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Votacion.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<Cata>> fetchCatasDeVotacion(String votacionId) async {
    final snapshot = await _db
        .collection('catas')
        .doc(votacionId)
        .collection('catas')
        .get();

    return snapshot.docs
        .map((doc) => Cata.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<Voto?> getVotoUsuario(
    String votacionId,
    String cataId,
    String userId,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection('catas')
        .doc(votacionId)
        .collection('catas')
        .doc(cataId)
        .collection('votos')
        .doc(userId)
        .get();

    if (doc.exists && doc.data() != null) {
      return Voto.fromJson(userId, doc.data()!);
    }
    return null;
  }

  Future<Map<String, String>> fetchNombresUsuarios(Set<String> uids) async {
    Map<String, String> nombres = {};

    for (var uid in uids) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (doc.exists) {
        nombres[uid] = doc.data()!['nombre'] ?? 'Desconocido';
      } else {
        nombres[uid] = 'Desconocido';
      }
    }

    return nombres;
  }

  Future<List<Votacion>> fetchCatas() async {
    final snapshot = await _db.collection('catas').orderBy('fecha').get();
    return snapshot.docs
        .map((doc) => Votacion.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> addVotacion(
    DateTime fecha,
    String creadorId,
    String nombre,
    List<Cata> catas,
  ) async {
    final votacionRef = await _db.collection('catas').add({
      'fecha': fecha.toIso8601String(),
      'creadorId': creadorId,
      'nombre': nombre,
    });

    for (var cata in catas) {
      await votacionRef.collection('catas').add(cata.toJson());
    }

    notifyListeners();
  }

  Future<void> addOrUpdateVoto(
    String votacionId,
    String cataId,
    String userId,
    Voto voto,
  ) async {
    await _db
        .collection('catas')
        .doc(votacionId)
        .collection('catas')
        .doc(cataId)
        .collection('votos')
        .doc(userId)
        .set(voto.toJson());
    notifyListeners();
  }

  Future<(Map<String, Map<String, Voto>>, Map<String, String>)> fetchResultados(
    String votacionId,
  ) async {
    final catasSnap = await _db
        .collection('catas')
        .doc(votacionId)
        .collection('catas')
        .get();
    Map<String, Map<String, Voto>> votosPorCata = {};
    Map<String, String> nombresDeCata = {};

    for (var cataDoc in catasSnap.docs) {
      final cataId = cataDoc.id;
      final nombre = cataDoc.data()['nombre'] ?? 'Cata';
      nombresDeCata[cataId] = nombre;

      final votosSnap = await cataDoc.reference.collection('votos').get();
      votosPorCata[cataId] = {
        for (var votoDoc in votosSnap.docs)
          votoDoc.id: Voto.fromJson(votoDoc.id, votoDoc.data()),
      };
    }

    return (votosPorCata, nombresDeCata);
  }
}
