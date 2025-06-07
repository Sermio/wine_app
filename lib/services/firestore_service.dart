import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wine_app/models/votacion.dart';
import 'package:wine_app/models/vino.dart';
import 'package:wine_app/models/voto.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Vino>> fetchVinosDeVotacion(String votacionId) async {
    final snapshot = await _db
        .collection('votaciones')
        .doc(votacionId)
        .collection('vinos')
        .get();

    return snapshot.docs
        .map((doc) => Vino.fromJson(doc.id, doc.data()))
        .toList();
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

  Future<List<Votacion>> fetchVotaciones() async {
    final snapshot = await _db.collection('votaciones').orderBy('fecha').get();
    return snapshot.docs
        .map((doc) => Votacion.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> addVotacion(
    DateTime fecha,
    String creadorId,
    String nombre,
    List<Vino> vinos,
  ) async {
    final votacionRef = await _db.collection('votaciones').add({
      'fecha': fecha.toIso8601String(),
      'creadorId': creadorId,
      'nombre': nombre,
    });

    for (var vino in vinos) {
      await votacionRef.collection('vinos').add(vino.toJson());
    }

    notifyListeners();
  }

  Future<void> addOrUpdateVoto(
    String votacionId,
    String vinoId,
    String userId,
    Voto voto,
  ) async {
    await _db
        .collection('votaciones')
        .doc(votacionId)
        .collection('vinos')
        .doc(vinoId)
        .collection('votos')
        .doc(userId)
        .set(voto.toJson());
    notifyListeners();
  }

  Future<(Map<String, Map<String, Voto>>, Map<String, String>)> fetchResultados(
    String votacionId,
  ) async {
    final vinosSnap = await _db
        .collection('votaciones')
        .doc(votacionId)
        .collection('vinos')
        .get();
    Map<String, Map<String, Voto>> votosPorVino = {};
    Map<String, String> nombresDeVino = {};

    for (var vinoDoc in vinosSnap.docs) {
      final vinoId = vinoDoc.id;
      final nombre = vinoDoc.data()['nombre'] ?? 'Vino';
      nombresDeVino[vinoId] = nombre;

      final votosSnap = await vinoDoc.reference.collection('votos').get();
      votosPorVino[vinoId] = {
        for (var votoDoc in votosSnap.docs)
          votoDoc.id: Voto.fromJson(votoDoc.id, votoDoc.data()),
      };
    }

    return (votosPorVino, nombresDeVino);
  }
}
