import 'package:flutter/material.dart';
import 'db.dart';

class PreguntasPage extends StatefulWidget {
  final String area;

  const PreguntasPage({super.key, required this.area});

  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> {
  List<Map<String, dynamic>> _preguntas = [];
  int _preguntaActual = 0;
  int _puntaje = 0;

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    try {
      final data = await DBHelper.obtenerPreguntasPorArea(widget.area);
      setState(() {
        _preguntas = data;
      });
    } catch (e) {
      print("Error al cargar preguntas: $e");
    }
  }

  void _responder(bool respuesta) {
    if (_preguntas.isEmpty) return;

    if (respuesta == (_preguntas[_preguntaActual]["respuesta"] == 1)) {
      _puntaje++;
    }

    setState(() {
      _preguntaActual++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_preguntas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Cargando ${widget.area}...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_preguntaActual >= _preguntas.length) {
      return Scaffold(
        appBar: AppBar(title: Text("Resultado - ${widget.area}")),
        body: Center(
          child: Text(
            "Tu puntaje: $_puntaje / ${_preguntas.length}",
            style: const TextStyle(fontSize: 22),
          ),
        ),
      );
    }

    final pregunta = _preguntas[_preguntaActual];

    return Scaffold(
      appBar: AppBar(title: Text("Preguntas de ${widget.area}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pregunta["texto"],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _responder(true),
              child: const Text("Verdadero"),
            ),
            ElevatedButton(
              onPressed: () => _responder(false),
              child: const Text("Falso"),
            ),
          ],
        ),
      ),
    );
  }
}
