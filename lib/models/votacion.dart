class Votacion {
  final String id;
  final DateTime fecha;
  final String creadorId;
  final String nombre;

  Votacion({
    required this.id,
    required this.fecha,
    required this.creadorId,
    required this.nombre,
  });

  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'creadorId': creadorId,
    'nombre': nombre,
  };

  static Votacion fromJson(String id, Map<String, dynamic> json) {
    return Votacion(
      id: id,
      fecha: DateTime.parse(json['fecha']),
      creadorId: json['creadorId'],
      nombre: json['nombre'] ?? '',
    );
  }
}
