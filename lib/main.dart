import 'package:flutter/material.dart';
import 'db.dart';
import 'preguntas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BORRAR base de datos antigua (solo para debug / desarrollo)
  await DBHelper.borrarBase();

  // Inicializar base de datos
  await DBHelper.database;

  // Imprimir todas las preguntas (debug)
  await DBHelper.imprimirTodasPreguntas();

  runApp(const PreguntasApp());
}

class PreguntasApp extends StatelessWidget {
  const PreguntasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explorador de Valles - Preguntas VF',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menú Principal")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBoton(context, "Lengua"),
            _buildBoton(context, "Historia"),
            _buildBoton(context, "Geografía"),
            _buildBoton(context, "Matemática"),
            _buildBoton(context, "Arte"),
          ],
        ),
      ),
    );
  }

  Widget _buildBoton(BuildContext context, String area) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        child: Text(area),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PreguntasPage(area: area)),
          );
        },
      ),
    );
  }
}
