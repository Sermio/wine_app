class ElementoCata {
  final String id;
  final String nombre;
  final String nombreAuxiliar;
  final String descripcion;
  final double precio;
  final String imagenUrl;

  ElementoCata({
    required this.id,
    required this.nombre,
    required this.nombreAuxiliar,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'nombreAuxiliar': nombreAuxiliar,
    'descripcion': descripcion,
    'precio': precio,
    'imagenUrl': imagenUrl,
  };

  static ElementoCata fromJson(String id, Map<String, dynamic> json) {
    return ElementoCata(
      id: id,
      nombre: json['nombre'],
      nombreAuxiliar: json['nombreAuxiliar'] ?? '',
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagenUrl'],
    );
  }
}
