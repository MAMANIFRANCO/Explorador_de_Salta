import 'package:flutter/material.dart';

/// Modelo que representa una categoría del juego
class Categoria {
  final int id;
  final String nombre;
  final String icono;
  final Color color;

  Categoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
  });

  /// Crea una Categoría desde un Map de la base de datos
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      icono: map['icono'] as String,
      color: Color(int.parse(map['color'] as String, radix: 16)),
    );
  }

  /// Convierte la Categoría a un Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'color': color.value.toRadixString(16).toUpperCase(),
    };
  }
}
