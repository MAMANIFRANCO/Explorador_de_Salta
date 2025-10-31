import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/palabra.dart';
import '../database/quien_soy_db.dart';
import '../services/sensor_service.dart';
import '../services/audio_service.dart';
import 'resultados_screen.dart';

class JuegoScreen extends StatefulWidget {
  final Categoria categoria;
  final int tiempoSegundos;

  const JuegoScreen({
    super.key,
    required this.categoria,
    this.tiempoSegundos = 60,
  });

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen>
    with SingleTickerProviderStateMixin {
  List<Palabra> _todasLasPalabras = [];
  List<Palabra> _palabrasRestantes = [];
  Palabra? _palabraActual;
  int _puntaje = 0;
  int _segundosRestantes = 0;
  bool _juegoIniciado = false;
  bool _juegoTerminado = false;
  bool _bloqueoAccion = false; // Bloquea acciones mientras se actualiza palabra

  final SensorService _sensorService = SensorService();
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _segundosRestantes = widget.tiempoSegundos;
    _inicializarAnimaciones();
    _cargarPalabras();
  }

  void _inicializarAnimaciones() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _cargarPalabras() async {
    try {
      final data =
          await QuienSoyDB.obtenerPalabrasPorCategoria(widget.categoria.id);
      setState(() {
        _todasLasPalabras = data.map((map) => Palabra.fromMap(map)).toList();
        _palabrasRestantes = List.from(_todasLasPalabras);
        _palabrasRestantes.shuffle(Random());
      });
    } catch (e) {
      debugPrint("Error cargando palabras: $e");
    }
  }

  void _iniciarJuego() {
    if (_palabrasRestantes.isEmpty) {
      _mostrarDialogoSinPalabras();
      return;
    }

    setState(() {
      _juegoIniciado = true;
      _palabraActual = _palabrasRestantes.first;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _segundosRestantes--);
      if (_segundosRestantes <= 0) _terminarJuego();
    });

    _sensorService.iniciar(
      onTiltUp: _manejarAcierto,
      onTiltDown: _manejarPasar,
    );
  }

  void _manejarAcierto() {
    if (!_juegoIniciado || _juegoTerminado || _bloqueoAccion) return;
    _bloqueoAccion = true;

    AudioService.reproducirAcierto();
    setState(() {
      _palabraActual?.marcarAcertada();
      _puntaje++;
      _palabrasRestantes.removeAt(0);
    });

    _animarCambio();
    _siguientePalabra();
    _bloqueoAccion = false;
  }

  void _manejarPasar() {
    if (!_juegoIniciado || _juegoTerminado || _bloqueoAccion) return;
    _bloqueoAccion = true;

    AudioService.reproducirPasar();
    setState(() => _palabrasRestantes.removeAt(0));

    _animarCambio();
    _siguientePalabra();
    _bloqueoAccion = false;
  }

  void _animarCambio() {
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _siguientePalabra() {
    if (_palabrasRestantes.isEmpty) {
      _terminarJuego();
      return;
    }
    setState(() => _palabraActual = _palabrasRestantes.first);
  }

  void _terminarJuego() {
    _timer?.cancel();
    _sensorService.detener();
    AudioService.reproducirTiempoAgotado();

    setState(() => _juegoTerminado = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadosScreen(
            categoria: widget.categoria,
            puntaje: _puntaje,
            palabrasJugadas: _todasLasPalabras
                .where((p) => !_palabrasRestantes.contains(p))
                .toList(),
          ),
        ),
      );
    });
  }

  void _mostrarDialogoSinPalabras() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sin palabras"),
        content: const Text("No hay palabras disponibles en esta categoría."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Volver"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorService.dispose();
    _animationController.dispose();
    AudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.categoria.color.withOpacity(0.7),
              widget.categoria.color,
            ],
          ),
        ),
        child: SafeArea(
          child:
              _juegoIniciado ? _buildPantallaJuego() : _buildPantallaInicio(),
        ),
      ),
    );
  }

  Widget _buildPantallaInicio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.categoria.icono, style: const TextStyle(fontSize: 100)),
          const SizedBox(height: 20),
          Text(
            widget.categoria.nombre,
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  "⏱️ Tiempo: $_segundosRestantes segundos",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("📱 Coloca el teléfono en tu frente",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const Text("⬆️ Inclina arriba si aciertas",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const Text("⬇️ Inclina abajo para pasar",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _iniciarJuego,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: widget.categoria.color,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "COMENZAR",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaJuego() {
    return Column(
      children: [
        // Barra superior con temporizador y puntaje
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Temporizador
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "$_segundosRestantes",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Puntaje
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "$_puntaje",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Palabra actual
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              _palabraActual?.texto ?? "...",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: widget.categoria.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const Spacer(),
        // Indicadores visuales de movimiento
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Column(
                children: [
                  Icon(Icons.arrow_upward, size: 50, color: Colors.white70),
                  Text("Acierto", style: TextStyle(color: Colors.white70)),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.arrow_downward, size: 50, color: Colors.white70),
                  Text("Pasar", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
