import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/voto.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Cata>> streamCatas() {
    return _db
        .collection('catas')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Cata.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> deleteCata(String id) async {
    final cataRef = _db.collection('catas').doc(id);

    final elementos = await cataRef.collection('elementos').get();
    for (var elemento in elementos.docs) {
      // Eliminar imagen del Storage si existe
      final data = elemento.data();
      final imagenUrl = data['imagenUrl'] as String?;
      if (imagenUrl != null && imagenUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imagenUrl);
          await ref.delete();
        } catch (e) {
          print('Error al eliminar imagen: $e');
        }
      }

      // Eliminar votos del elemento
      final votos = await elemento.reference.collection('votos').get();
      for (var voto in votos.docs) {
        await voto.reference.delete();
      }

      // Eliminar el documento del elemento
      await elemento.reference.delete();
    }

    // Eliminar el documento de la cata
    await cataRef.delete();
    notifyListeners();
  }

  Future<void> addCata(Cata cata) async {
    await _db.collection('catas').doc(cata.id).set(cata.toJson());
  }

  Future<Cata?> fetchCata(String cataId) async {
    final doc = await _db.collection('catas').doc(cataId).get();
    if (doc.exists) {
      return Cata.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  Future<List<ElementoCata>> fetchElementosDeCata(String cataId) async {
    final snapshot = await _db
        .collection('catas')
        .doc(cataId)
        .collection('elementos')
        .get();

    return snapshot.docs
        .map((doc) => ElementoCata.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<Voto?> getVotoUsuario(
    String cataId,
    String elementoId,
    String userId,
  ) async {
    if (cataId.trim().isEmpty ||
        elementoId.trim().isEmpty ||
        userId.trim().isEmpty) {
      throw ArgumentError('cataId, elementoId y userId no pueden estar vacíos');
    }

    final doc = await _db
        .collection('catas')
        .doc(cataId)
        .collection('elementos')
        .doc(elementoId)
        .collection('votos')
        .doc(userId)
        .get();

    if (doc.exists && doc.data() != null) {
      return Voto.fromJson(userId, doc.data()!);
    }
    return null;
  }

  Future<Map<String, String>> fetchNombresUsuarios(Set<String> uids) async {
    if (uids.isEmpty) return {};

    // Usar consultas en paralelo en lugar de secuenciales
    final futures = uids.map((uid) async {
      try {
        final doc = await _db.collection('usuarios').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return MapEntry<String, String>(
            uid,
            doc.data()!['nombre'] ?? 'Desconocido',
          );
        } else {
          return MapEntry<String, String>(uid, 'Desconocido');
        }
      } catch (e) {
        print('Error al obtener usuario $uid: $e');
        return MapEntry<String, String>(uid, 'Desconocido');
      }
    });

    final results = await Future.wait(futures);
    return Map<String, String>.fromEntries(results);
  }

  Future<List<Cata>> fetchCatas() async {
    final snapshot = await _db.collection('catas').orderBy('fecha').get();
    return snapshot.docs
        .map((doc) => Cata.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> addVotacion(Cata cata) async {
    if (cata.id.trim().isEmpty)
      throw Exception('El ID de la cata no puede estar vacío');
    for (var elemento in cata.elementos) {
      if (elemento.id.trim().isEmpty)
        throw Exception('Todos los elementos deben tener un ID definido');
    }

    final cataRef = _db.collection('catas').doc(cata.id);
    await cataRef.set({
      'nombre': cata.nombre,
      'fecha': cata.fecha.toIso8601String(),
      'creadorId': cata.creadorId,
    });

    for (var elemento in cata.elementos) {
      await cataRef
          .collection('elementos')
          .doc(elemento.id)
          .set(elemento.toJson());
    }

    notifyListeners();
  }

  Future<void> addOrUpdateVoto(
    String cataId,
    String elementoId,
    String userId,
    Voto voto,
  ) async {
    await _db
        .collection('catas')
        .doc(cataId)
        .collection('elementos')
        .doc(elementoId)
        .collection('votos')
        .doc(userId)
        .set(voto.toJson());
    notifyListeners();
  }

  Future<
    (
      Map<String, Map<String, Voto>> votosPorElemento,
      Map<String, String> nombresDeElemento,
    )
  >
  fetchResultados(String cataId) async {
    final elementosSnap = await _db
        .collection('catas')
        .doc(cataId)
        .collection('elementos')
        .get();

    Map<String, Map<String, Voto>> votosPorElemento = {};
    Map<String, String> nombresDeElemento = {};

    for (var elementoDoc in elementosSnap.docs) {
      final elementoId = elementoDoc.id;
      final nombre = elementoDoc.data()['nombreAuxiliar'] ?? 'Elemento';
      nombresDeElemento[elementoId] = nombre;

      final votosSnap = await elementoDoc.reference.collection('votos').get();
      votosPorElemento[elementoId] = {
        for (var votoDoc in votosSnap.docs)
          votoDoc.id: Voto.fromJson(votoDoc.id, votoDoc.data()),
      };
    }

    return (votosPorElemento, nombresDeElemento);
  }

  Future<
    (
      Map<String, Map<String, Voto>>, // votos por elemento
      Map<String, String>, // nombres reales
      Map<String, String>, // descripciones
      Map<String, String>, // nombres auxiliares
      Map<String, double>, // precios
      Map<String, String>, // imagenes
    )
  >
  fetchResultadosConNombres(String cataId) async {
    final elementosSnap = await _db
        .collection('catas')
        .doc(cataId)
        .collection('elementos')
        .get();

    Map<String, Map<String, Voto>> votosPorElemento = {};
    Map<String, String> nombres = {};
    Map<String, String> descripciones = {};
    Map<String, String> nombresAux = {};
    Map<String, double> precios = {};
    Map<String, String> imagenes = {};

    // Procesar datos de elementos primero
    for (var doc in elementosSnap.docs) {
      final elementoId = doc.id;
      final data = doc.data();

      final nombre = data['nombre'] ?? 'Elemento';
      final descripcion = data['descripcion'] ?? '';
      final nombreAux = data['nombreAuxiliar'] ?? 'Elemento';
      final precio = (data['precio'] as num?)?.toDouble();
      final imagenUrl = data['imagenUrl'] ?? '';

      nombres[elementoId] = nombre;
      descripciones[elementoId] = descripcion;
      nombresAux[elementoId] = nombreAux;

      if (precio != null) {
        precios[elementoId] = precio;
      }

      if (imagenUrl.isNotEmpty) {
        imagenes[elementoId] = imagenUrl;
      }
    }

    // Obtener votos en paralelo para todos los elementos
    final votosFutures = elementosSnap.docs.map((doc) async {
      try {
        final votosSnap = await doc.reference.collection('votos').get();
        return MapEntry(doc.id, {
          for (var voto in votosSnap.docs)
            voto.id: Voto.fromJson(voto.id, voto.data()),
        });
      } catch (e) {
        print('Error al obtener votos para elemento ${doc.id}: $e');
        return MapEntry(doc.id, <String, Voto>{});
      }
    });

    final votosResults = await Future.wait(votosFutures);
    votosPorElemento = Map.fromEntries(votosResults);

    return (
      votosPorElemento,
      nombres,
      descripciones,
      nombresAux,
      precios,
      imagenes,
    );
  }

  Future<String?> getImagenUrl(String elementoId) async {
    try {
      final ref = FirebaseStorage.instance.ref('elementos/$elementoId.jpg');
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, Voto>> fetchVotosDeElemento(
    String votacionId,
    String elementoId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('catas')
        .doc(votacionId)
        .collection('elementos')
        .doc(elementoId)
        .collection('votos')
        .get();

    return {
      for (var doc in snapshot.docs) doc.id: Voto.fromJson(doc.id, doc.data()),
    };
  }
}
