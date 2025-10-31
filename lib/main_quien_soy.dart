import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/quien_soy_db.dart';
import 'screens/home_screen.dart';

/// Punto de entrada principal de la aplicación "¿Quién soy yo?"
void main() async {
  // Asegurar que los bindings estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación (solo vertical)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // IMPORTANTE: Descomentar solo en desarrollo si necesitas recrear la DB
  // await QuienSoyDB.borrarBase();

  // Inicializar base de datos
  await QuienSoyDB.database;

  // Debug: imprimir categorías y palabras disponibles
  await QuienSoyDB.imprimirTodo();

  runApp(const QuienSoyApp());
}

/// Widget principal de la aplicación
class QuienSoyApp extends StatelessWidget {
  const QuienSoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '¿Quién Soy Yo?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
