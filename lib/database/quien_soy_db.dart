import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Base de datos para el juego "¿Quién soy yo?"
/// Maneja categorías y palabras/personajes
class QuienSoyDB {
  static Database? _db;
  static const int _version = 2;

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
      version: _version,
      onCreate: (db, version) async {
        await _crearTablas(db);
        await _insertarDatosIniciales(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print("Actualizando DB de versión $oldVersion a $newVersion");
        await db.execute("DROP TABLE IF EXISTS palabras");
        await db.execute("DROP TABLE IF EXISTS categorias");
        await _crearTablas(db);
        await _insertarDatosIniciales(db);
      },
    );
  }

  /// Crea las tablas de la DB
  static Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE categorias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        icono TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE palabras(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        texto TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        imagen_url TEXT,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
      )
    ''');
  }

  /// Inserta datos iniciales en la DB
  static Future<void> _insertarDatosIniciales(Database db) async {
    // Categorías iniciales
    List<Map<String, String>> categorias = [
      {"nombre": "Animales", "icono": "🐾", "color": "FF4CAF50"},
      {"nombre": "Películas", "icono": "🎬", "color": "FF2196F3"},
      {"nombre": "Famosos", "icono": "⭐", "color": "FFFF9800"},
      {"nombre": "Deportes", "icono": "⚽", "color": "FFF44336"},
      {"nombre": "Profesiones", "icono": "💼", "color": "FF9C27B0"},
    ];

    for (var cat in categorias) {
      await db.insert("categorias", cat);
    }

    // Palabras por categoría con imágenes
    Map<int, List<Map<String, String>>> palabrasPorCategoria = {
      1: [
        {"texto": "Mulita", "imagenUrl": "assets/images/animales/mulita.jpeg"},
        {
          "texto": "Guanaco",
          "imagenUrl": "assets/images/animales/guanaco.jpeg"
        },
        {"texto": "Llama", "imagenUrl": "assets/images/animales/llama.jpg"},
        {
          "texto": "Corzuela",
          "imagenUrl": "assets/images/animales/corzuela.jpg"
        },
        {
          "texto": "Tatú Carreta",
          "imagenUrl": "assets/images/animales/tatuCarreta.jpg"
        },
        {"texto": "Alpaca", "imagenUrl": "assets/images/animales/alpaca.jpg"},
        {
          "texto": "Gato Montés",
          "imagenUrl": "assets/images/animales/gato_montes.png"
        },
        {
          "texto": "Pava de Monte",
          "imagenUrl": "assets/images/animales/pava_de_monte.jpg"
        },
        {
          "texto": "Vizcacha",
          "imagenUrl": "assets/images/animales/Vizcacha.jpg"
        },
        {"texto": "Cuis", "imagenUrl": "assets/images/animales/Cuis.jpeg"},
        {"texto": "Tapir", "imagenUrl": "assets/images/animales/Tapir.jpg"},
        {
          "texto": "Zorro de monte",
          "imagenUrl": "assets/images/animales/zorro.jpg"
        },
        {
          "texto": "Pecarí de Collar",
          "imagenUrl": "assets/images/animales/Pecari.jpg"
        },
        {
          "texto": "Yaguarete",
          "imagenUrl": "assets/images/animales/yaguarete.jpg"
        },
        {"texto": "Coatí", "imagenUrl": "assets/images/animales/coati.jpg"},
        {
          "texto": "Condor Andino",
          "imagenUrl": "assets/images/animales/Condor-Andino.png"
        },
      ],
      2: [
        {
          "texto": "Titanic",
          "imagenUrl": "assets/images/peliculas/titanic.png"
        },
        {"texto": "Avatar", "imagenUrl": "assets/images/peliculas/avatar.png"},
        {
          "texto": "El Padrino",
          "imagenUrl": "assets/images/peliculas/padrino.png"
        },
        {
          "texto": "Inception",
          "imagenUrl": "assets/images/peliculas/inception.png"
        },
        {"texto": "Matrix", "imagenUrl": "assets/images/peliculas/matrix.png"},
      ],

      4: [
        {
          "texto": "Gimnasia y Tiro",
          "imagenUrl": "assets/images/futbol/gyt.png"
        },
        {
          "texto": "Juventud Antoniana",
          "imagenUrl": "assets/images/futbol/cja.png"
        },
        {"texto": "Central Norte", "imagenUrl": "assets/images/futbol/cn.png"},
        {"texto": "Atletico Mitre", "imagenUrl": "assets/images/futbol/am.png"},
        {
          "texto": "Club Atlético Social Boroquémica",
          "imagenUrl": "assets/images/futbol/brq.png"
        },
        {
          "texto": "Club Atlético Chicoana",
          "imagenUrl": "assets/images/futbol/cha.png"
        },
        {
          "texto": "Club Atlético Nobleza",
          "imagenUrl": "assets/images/futbol/can.png"
        },
        {
          "texto": "Club Atlético Sportivo El Carril",
          "imagenUrl": "assets/images/futbol/casc.png"
        },
      ],
      // Agregá aquí más categorías si querés
    };

    for (var catId in palabrasPorCategoria.keys) {
      for (var palabra in palabrasPorCategoria[catId]!) {
        await db.insert("palabras", {
          "texto": palabra["texto"],
          "categoria_id": catId,
          // ✅ Usa imagenUrl si existe, o imagen como alternativa
          "imagen_url": palabra["imagenUrl"] ?? palabra["imagen"],
        });
      }
    }
  } // <-- cierre del método

  /// Obtiene todas las categorías
  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final db = await database;
    return await db.query("categorias", orderBy: "nombre ASC");
  }

  /// Obtiene todas las palabras de una categoría específica
  static Future<List<Map<String, dynamic>>> obtenerPalabrasPorCategoria(
      int categoriaId) async {
    final db = await database;
    return await db.query(
      "palabras",
      where: "categoria_id = ?",
      whereArgs: [categoriaId],
    );
  }

  /// Agrega una nueva categoría
  static Future<int> agregarCategoria(
      String nombre, String icono, String color) async {
    final db = await database;
    return await db.insert(
        "categorias", {"nombre": nombre, "icono": icono, "color": color});
  }

  /// Agrega una nueva palabra a una categoría
  static Future<int> agregarPalabra(String texto, int categoriaId,
      {String? imagenUrl}) async {
    final db = await database;
    return await db.insert("palabras", {
      "texto": texto,
      "categoria_id": categoriaId,
      "imagen_url": imagenUrl,
    });
  }

  /// Debug: imprime todas las categorías y palabras
  static Future<void> imprimirTodo() async {
    final categorias = await obtenerCategorias();
    print("===== CATEGORÍAS =====");
    for (var cat in categorias) {
      print("${cat['id']}: ${cat['nombre']} ${cat['icono']}");
      final palabras = await obtenerPalabrasPorCategoria(cat['id']);
      print("  Palabras (${palabras.length}):");
      for (var p in palabras) {
        print("   - ${p['texto']} (${p['imagen_url']})");
      }
    }
    print("======================");
  }
}
