import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<void> borrarBase() async {
    String path = join(await getDatabasesPath(), "preguntas.db");
    if (await File(path).exists()) {
      await deleteDatabase(path);
      print("Base de datos eliminada correctamente");
    }
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), "preguntas.db");
    return await openDatabase(
      path,
      version: 2, // importante: incrementar versión si cambiamos la tabla
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE preguntas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            texto TEXT NOT NULL,
            respuesta INTEGER NOT NULL,
            area TEXT NOT NULL
          )
        ''');

        // Preguntas de ejemplo
        await db.insert("preguntas", {
          "texto": "La Batalla de Salta fue en 1813",
          "respuesta": 1,
          "area": "Historia",
        });
        await db.insert("preguntas", {
          "texto": "Martín Miguel de Güemes nació en Tucumán",
          "respuesta": 0,
          "area": "Historia",
        });
        await db.insert("preguntas", {
          "texto": "El sustantivo es una clase de palabra",
          "respuesta": 1,
          "area": "Lengua",
        });
        await db.insert("preguntas", {
          "texto": "El poncho salteño es de color rojo y negro",
          "respuesta": 1,
          "area": "Arte",
        });
        await db.insert("preguntas", {
          "texto": "Salta tiene 24 departamentos",
          "respuesta": 0,
          "area": "Geografía",
        });
        await db.insert("preguntas", {
          "texto":
              "Cerrillos es el departamento más pequeño del territorio provincial",
          "respuesta": 1,
          "area": "Geografía",
        });
        await db.insert("preguntas", {
          "texto":
              "Por cada herradura se utilizan 4 clavos y por cada caballo se usan 4 herraduras. Si tengo 4 caballos, ¿Necesito 16 herraduras y 64 clavos?",
          "respuesta": 1,
          "area": "Matemática",
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE preguntas ADD COLUMN area TEXT DEFAULT 'General'",
          );
        }
      },
    );
  }

  // Debug: listar todas las preguntas
  static Future<void> imprimirTodasPreguntas() async {
    final db = await database;
    final resultado = await db.query("preguntas");
    print("===== Todas las preguntas =====");
    for (var fila in resultado) {
      print(
        "ID: ${fila['id']}, Texto: ${fila['texto']}, Respuesta: ${fila['respuesta']}, Área: ${fila['area']}",
      );
    }
    print("===============================");
  }

  // Obtener preguntas por área, ignorando mayúsculas y tildes
  static Future<List<Map<String, dynamic>>> obtenerPreguntasPorArea(
    String area,
  ) async {
    final db = await database;
    // Convertimos a minúscula y usamos LIKE para evitar problemas con acentos
    return await db.query(
      "preguntas",
      where: "LOWER(area) LIKE ?",
      whereArgs: [area.toLowerCase()],
    );
  }
}
