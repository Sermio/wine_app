class Voto {
  final String usuarioId;
  final int? posicion; // Para sistema nuevo de ranking
  final double? puntuacion; // Para sistema antiguo de puntuación
  final String comentario;
  final bool esSistemaAntiguo; // Flag para identificar el tipo de voto

  Voto({
    required this.usuarioId,
    this.posicion,
    this.puntuacion,
    required this.comentario,
    this.esSistemaAntiguo = false,
  });

  Map<String, dynamic> toJson() => {
    if (esSistemaAntiguo) 'puntuacion': puntuacion,
    if (!esSistemaAntiguo) 'posicion': posicion,
    'comentario': comentario,
  };

  static Voto fromJson(
    String uid,
    Map<String, dynamic> json, {
    int? totalElementos,
  }) {
    if (json.containsKey('posicion')) {
      // Votación nueva con sistema de ranking
      return Voto(
        usuarioId: uid,
        posicion: json['posicion'] as int,
        comentario: json['comentario'] ?? '',
        esSistemaAntiguo: false,
      );
    } else if (json.containsKey('puntuacion')) {
      // Votación antigua con sistema de puntuación 1-10
      // Mantener el valor original sin conversión
      return Voto(
        usuarioId: uid,
        puntuacion: (json['puntuacion'] as num).toDouble(),
        comentario: json['comentario'] ?? '',
        esSistemaAntiguo: true,
      );
    } else {
      // Fallback si no hay ningún campo
      return Voto(
        usuarioId: uid,
        posicion: 1,
        comentario: json['comentario'] ?? '',
        esSistemaAntiguo: false,
      );
    }
  }
}
