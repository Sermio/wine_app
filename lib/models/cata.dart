import 'package:wine_app/models/elemento_cata.dart';

class Cata {
  final String id;
  final String nombre;
  final DateTime fecha;
  final String creadorId;
  final List<ElementoCata> elementos;
  final bool? abierta;

  Cata({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.creadorId,
    required this.elementos,
    this.abierta,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'fecha': fecha.toIso8601String(),
    'creadorId': creadorId,
    'elementos': elementos.map((e) => e.toJson()).toList(),
    if (abierta != null) 'abierta': abierta,
  };

  static Cata fromJson(String id, Map<String, dynamic> json) {
    return Cata(
      id: id,
      nombre: json['nombre'],
      fecha: DateTime.parse(json['fecha']),
      creadorId: json['creadorId'],
      elementos: [],
      abierta: json['abierta'],
    );
  }
}
