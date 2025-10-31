import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla de configuración del juego
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  int _tiempoSeleccionado = 60; // Tiempo por defecto
  bool _sonidoActivado = true;
  bool _vibracionActivada = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  /// Carga la configuración guardada
  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tiempoSeleccionado = prefs.getInt('tiempo') ?? 60;
      _sonidoActivado = prefs.getBool('sonido') ?? true;
      _vibracionActivada = prefs.getBool('vibracion') ?? true;
    });
  }

  /// Guarda la configuración
  Future<void> _guardarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tiempo', _tiempoSeleccionado);
    await prefs.setBool('sonido', _sonidoActivado);
    await prefs.setBool('vibracion', _vibracionActivada);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Configuración guardada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configuración"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.yellow.shade100],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Sección de tiempo
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange, size: 30),
                        SizedBox(width: 10),
                        Text(
                          "Duración del juego",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Tiempo: $_tiempoSeleccionado segundos",
                      style: TextStyle(fontSize: 16),
                    ),
                    Slider(
                      value: _tiempoSeleccionado.toDouble(),
                      min: 30,
                      max: 120,
                      divisions: 9,
                      label: "$_tiempoSeleccionado seg",
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() {
                          _tiempoSeleccionado = value.toInt();
                        });
                      },
                    ),
                    Text(
                      "Elige entre 30 y 120 segundos",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Sección de sonido
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Icon(Icons.volume_up, color: Colors.orange),
                    SizedBox(width: 10),
                    Text(
                      "Sonido",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: Text("Activar efectos de sonido"),
                value: _sonidoActivado,
                activeColor: Colors.orange,
                onChanged: (value) {
                  setState(() {
                    _sonidoActivado = value;
                  });
                },
              ),
            ),
            SizedBox(height: 10),

            // Sección de vibración
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Icon(Icons.vibration, color: Colors.orange),
                    SizedBox(width: 10),
                    Text(
                      "Vibración",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: Text("Activar feedback táctil"),
                value: _vibracionActivada,
                activeColor: Colors.orange,
                onChanged: (value) {
                  setState(() {
                    _vibracionActivada = value;
                  });
                },
              ),
            ),
            SizedBox(height: 40),

            // Botón para guardar
            ElevatedButton.icon(
              onPressed: _guardarConfiguracion,
              icon: Icon(Icons.save),
              label: Text("Guardar configuración"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
