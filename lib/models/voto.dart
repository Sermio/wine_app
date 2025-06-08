class Voto {
  final String usuarioId;
  final double puntuacion;
  final String comentario;

  Voto({
    required this.usuarioId,
    required this.puntuacion,
    required this.comentario,
  });

  Map<String, dynamic> toJson() => {
    'puntuacion': puntuacion,
    'comentario': comentario,
  };

  static Voto fromJson(String uid, Map<String, dynamic> json) {
    return Voto(
      usuarioId: uid,
      puntuacion: json['puntuacion'],
      comentario: json['comentario'],
    );
  }
}
