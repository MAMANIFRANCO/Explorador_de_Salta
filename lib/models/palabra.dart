/// Modelo que representa una palabra o personaje del juego
class Palabra {
  final int id;
  final String texto;
  final int categoriaId;
  bool acertada; // Para tracking durante el juego

  Palabra({
    required this.id,
    required this.texto,
    required this.categoriaId,
    this.acertada = false,
  });

  /// Crea una Palabra desde un Map de la base de datos
  factory Palabra.fromMap(Map<String, dynamic> map) {
    return Palabra(
      id: map['id'] as int,
      texto: map['texto'] as String,
      categoriaId: map['categoria_id'] as int,
    );
  }

  /// Convierte la Palabra a un Map para la base de datos
  Map<String, dynamic> toMap() {
    return {'id': id, 'texto': texto, 'categoria_id': categoriaId};
  }

  /// Marca la palabra como acertada
  void marcarAcertada() {
    acertada = true;
  }
}
