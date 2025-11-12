class Palabra {
  final int id;
  final String texto;
  final int categoriaId;
  final String? imagenUrl; // ✅ <-- nuevo campo
  bool acertada;

  Palabra({
    required this.id,
    required this.texto,
    required this.categoriaId,
    this.imagenUrl,
    this.acertada = false,
  });

  /// Crea una instancia de Palabra desde un mapa (registro SQLite)
  factory Palabra.fromMap(Map<String, dynamic> map) {
    return Palabra(
      id: map['id'] as int,
      texto: map['texto'] as String,
      categoriaId: map['categoria_id'] as int,
      imagenUrl: map['imagen_url'] as String?, // ✅ <-- lee imagen desde DB
    );
  }

  /// Convierte el objeto a mapa para guardar en la DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'texto': texto,
      'categoria_id': categoriaId,
      'imagen_url': imagenUrl,
    };
  }

  /// Marca la palabra como acertada
  void marcarAcertada() {
    acertada = true;
  }
}
