import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  List<Palabra> _todasLasPalabras = [];
  List<Palabra> _palabrasRestantes = [];
  Palabra? _palabraActual;
  int _puntaje = 0;
  int _segundosRestantes = 0;
  bool _juegoIniciado = false;
  bool _juegoTerminado = false;
  bool _bloqueoAccion = false;
  bool _juegoPausado = false;

  final SensorService _sensorService = SensorService();
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fondoController;

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

    _fondoController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  Future<void> _cargarPalabras() async {
    try {
      final data =
          await QuienSoyDB.obtenerPalabrasPorCategoria(widget.categoria.id);
      setState(() {
        _todasLasPalabras = data.map((map) => Palabra.fromMap(map)).toList();
        _palabrasRestantes = List.from(_todasLasPalabras)..shuffle(Random());
      });
    } catch (e) {
      debugPrint("Error cargando palabras: $e");
    }
  }

  Future<void> _iniciarJuego() async {
    if (_palabrasRestantes.isEmpty) {
      _mostrarDialogoSinPalabras();
      return;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    setState(() {
      _juegoIniciado = true;
      _palabraActual = _palabrasRestantes.first;
    });

    _iniciarTemporizador();

    // Activamos sensor: pantalla hacia arriba = acierto, hacia abajo = pasar
    _sensorService.iniciar(
      onTiltUp: _manejarAcierto,
      onTiltDown: _manejarPasar,
    );
  }

  void _iniciarTemporizador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_juegoPausado) {
        setState(() => _segundosRestantes--);
        if (_segundosRestantes <= 0) _terminarJuego();
      }
    });
  }

  void _pausarJuego() {
    setState(() => _juegoPausado = true);
    _sensorService.detener();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Juego en pausa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("¿Qué querés hacer?"),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            label: const Text("Reanudar"),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _juegoPausado = false);
              _sensorService.iniciar(
                onTiltUp: _manejarAcierto,
                onTiltDown: _manejarPasar,
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.menu, color: Colors.orange),
            label: const Text("Volver al menú"),
            onPressed: () async {
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              if (mounted) Navigator.pop(context); // cierra modal
              if (mounted) Navigator.pop(context); // vuelve al menú
            },
          ),
        ],
      ),
    );
  }

  void _manejarAcierto() {
    if (!_juegoIniciado || _juegoTerminado || _bloqueoAccion || _juegoPausado)
      return;
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
    if (!_juegoIniciado || _juegoTerminado || _bloqueoAccion || _juegoPausado)
      return;
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

  Future<void> _terminarJuego() async {
    _timer?.cancel();
    _sensorService.detener();
    AudioService.reproducirTiempoAgotado();

    setState(() => _juegoTerminado = true);

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _timer?.cancel();
    _sensorService.dispose();
    _animationController.dispose();
    _fondoController.dispose();
    AudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fondoController,
        builder: (context, child) {
          final color1 = widget.categoria.color
              .withOpacity(0.7 + 0.1 * sin(_fondoController.value * pi));
          final color2 = widget.categoria.color
              .withOpacity(1.0 - 0.1 * sin(_fondoController.value * pi));

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color1, color2],
              ),
            ),
            child: SafeArea(
              child: _juegoIniciado
                  ? _buildPantallaJuego()
                  : _buildPantallaInicio(),
            ),
          );
        },
      ),
    );
  }

  // ------------------- PANTALLA INICIO -------------------
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
                const Text("📱 Colocá el teléfono en tu frente",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const Text("⬆️ Pantalla hacia arriba = Acierto",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const Text("⬇️ Pantalla hacia abajo = Pasar",
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

  // ------------------- PANTALLA JUEGO -------------------
  Widget _buildPantallaJuego() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIndicador(
                            Icons.timer, _segundosRestantes.toString()),
                        _buildIndicador(Icons.star, _puntaje.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(30),
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Column(
                          children: [
                            Icon(Icons.arrow_upward,
                                size: 50, color: Colors.white70),
                            Text("Acierto",
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.arrow_downward,
                                size: 50, color: Colors.white70),
                            Text("Pasar",
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.pause_circle_filled,
                    color: Colors.white, size: 40),
                onPressed: _pausarJuego,
                tooltip: "Pausar juego",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicador(IconData icono, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icono, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
