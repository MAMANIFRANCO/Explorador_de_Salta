import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Base de datos para el juego "¿Quién soy yo?"
/// Maneja categorías y palabras/personajes
class QuienSoyDB {
  static Database? _db;

  /// Obtiene la instancia de la base de datos
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  /// Borra la base de datos (útil para desarrollo/debug)
  static Future<void> borrarBase() async {
    String path = join(await getDatabasesPath(), "quien_soy.db");
    if (await File(path).exists()) {
      await deleteDatabase(path);
      print("Base de datos 'quien_soy.db' eliminada correctamente");
    }
  }

  /// Inicializa la base de datos y crea las tablas
  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), "quien_soy.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla de categorías
        await db.execute('''
          CREATE TABLE categorias(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL UNIQUE,
            icono TEXT NOT NULL,
            color TEXT NOT NULL
          )
        ''');

        // Tabla de palabras/personajes
        await db.execute('''
          CREATE TABLE palabras(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            texto TEXT NOT NULL,
            categoria_id INTEGER NOT NULL,
            FOREIGN KEY (categoria_id) REFERENCES categorias(id)
          )
        ''');

        // Insertar categorías iniciales
        await db.insert("categorias", {
          "nombre": "Animales",
          "icono": "🐾",
          "color": "FF4CAF50", // Verde
        });
        await db.insert("categorias", {
          "nombre": "Películas",
          "icono": "🎬",
          "color": "FF2196F3", // Azul
        });
        await db.insert("categorias", {
          "nombre": "Famosos",
          "icono": "⭐",
          "color": "FFFF9800", // Naranja
        });
        await db.insert("categorias", {
          "nombre": "Deportes",
          "icono": "⚽",
          "color": "FFF44336", // Rojo
        });
        await db.insert("categorias", {
          "nombre": "Profesiones",
          "icono": "💼",
          "color": "FF9C27B0", // Púrpura
        });

        // Insertar palabras de ejemplo - ANIMALES
        List<String> animales = [
          "Mulita",
          "Guanaco",
          "Llama",
          "Zorro",
          "Gallina",
          "Tapir",
          "Oso hormiguero",
          "Corzuela",
          "Mataco",
        ];
        for (var animal in animales) {
          await db.insert("palabras", {"texto": animal, "categoria_id": 1});
        }

        // PELÍCULAS
        List<String> peliculas = [
          "Titanic",
          "Avatar",
          "El Padrino",
          "Inception",
          "Matrix",
          "Jurassic Park",
          "Star Wars",
          "Harry Potter",
          "El Rey León",
          "Frozen",
          "Toy Story",
          "Shrek",
          "Los Avengers",
          "Spider-Man",
          "Batman",
          "Superman",
          "Gladiador",
          "El Origen",
          "Interestelar",
          "Joker",
        ];
        for (var pelicula in peliculas) {
          await db.insert("palabras", {"texto": pelicula, "categoria_id": 2});
        }

        // FAMOSOS
        List<String> famosos = [
          "Lionel Messi",
          "Cristiano Ronaldo",
          "Taylor Swift",
          "Shakira",
          "Leonardo DiCaprio",
          "Jennifer Aniston",
          "Will Smith",
          "Rihanna",
          "Beyoncé",
          "Justin Bieber",
          "Ariana Grande",
          "Ed Sheeran",
          "Elon Musk",
          "Bill Gates",
          "Steve Jobs",
          "Albert Einstein",
          "Pablo Picasso",
          "Frida Kahlo",
          "Diego Maradona",
          "Michael Jackson",
        ];
        for (var famoso in famosos) {
          await db.insert("palabras", {"texto": famoso, "categoria_id": 3});
        }

        // DEPORTES
        List<String> deportes = [
          "Fútbol",
          "Básquetbol",
          "Tenis",
          "Voleibol",
          "Natación",
          "Atletismo",
          "Ciclismo",
          "Boxeo",
          "Golf",
          "Rugby",
          "Hockey",
          "Esquí",
          "Snowboard",
          "Surf",
          "Patinaje",
          "Gimnasia",
          "Esgrima",
          "Judo",
          "Karate",
          "Escalada",
        ];
        for (var deporte in deportes) {
          await db.insert("palabras", {"texto": deporte, "categoria_id": 4});
        }

        // PROFESIONES
        List<String> profesiones = [
          "Médico",
          "Profesor",
          "Ingeniero",
          "Abogado",
          "Arquitecto",
          "Chef",
          "Piloto",
          "Bombero",
          "Policía",
          "Dentista",
          "Enfermero",
          "Programador",
          "Diseñador",
          "Periodista",
          "Fotógrafo",
          "Músico",
          "Actor",
          "Escritor",
          "Científico",
          "Astronauta",
        ];
        for (var profesion in profesiones) {
          await db.insert("palabras", {"texto": profesion, "categoria_id": 5});
        }
      },
    );
  }

  /// Obtiene todas las categorías
  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final db = await database;
    return await db.query("categorias", orderBy: "nombre ASC");
  }

  /// Obtiene todas las palabras de una categoría específica
  static Future<List<Map<String, dynamic>>> obtenerPalabrasPorCategoria(
    int categoriaId,
  ) async {
    final db = await database;
    return await db.query(
      "palabras",
      where: "categoria_id = ?",
      whereArgs: [categoriaId],
    );
  }

  /// Agrega una nueva categoría
  static Future<int> agregarCategoria(
    String nombre,
    String icono,
    String color,
  ) async {
    final db = await database;
    return await db.insert("categorias", {
      "nombre": nombre,
      "icono": icono,
      "color": color,
    });
  }

  /// Agrega una nueva palabra a una categoría
  static Future<int> agregarPalabra(String texto, int categoriaId) async {
    final db = await database;
    return await db.insert("palabras", {
      "texto": texto,
      "categoria_id": categoriaId,
    });
  }

  /// Debug: imprime todas las categorías y palabras
  static Future<void> imprimirTodo() async {
    final categorias = await obtenerCategorias();
    print("===== CATEGORÍAS =====");
    for (var cat in categorias) {
      print("${cat['id']}: ${cat['nombre']} ${cat['icono']}");
      final palabras = await obtenerPalabrasPorCategoria(cat['id']);
      print("  Palabras: ${palabras.length}");
    }
    print("======================");
  }
}
