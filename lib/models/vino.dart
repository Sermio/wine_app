class Vino {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;

  Vino({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'imagenUrl': imagenUrl,
  };

  static Vino fromJson(String id, Map<String, dynamic> json) {
    return Vino(
      id: id,
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagenUrl'],
    );
  }
}
