import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Datos
  List<Palabra> _todasLasPalabras = [];
  List<Palabra> _palabrasRestantes = [];
  Palabra? _palabraActual;

  // Estado
  int _puntaje = 0;
  int _segundosRestantes = 0;
  bool _juegoIniciado = false;
  bool _juegoTerminado = false;
  bool _bloqueoAccion = false;
  bool _juegoPausado = false;
  bool _mostrandoCuentaRegresiva = false;
  int _contador = 3;

  // Servicios y timers
  final SensorService _sensorService = SensorService();
  Timer? _timer;

  // Overlay acierto/pasar
  late AnimationController _overlayController;
  late Animation<double> _overlayOpacity;
  Color _colorOverlay = Colors.transparent;

  // Paleta
  final Color _fondoOscuro = const Color(0xFF0F0C29); // azul marino profundo
  final Color _fondoOscuro2 = const Color(0xFF1C1F2E); // tono compañero
  final Color _bordeAcento = const Color(0xFF00F5FF); // azul eléctrico

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _segundosRestantes = widget.tiempoSegundos;

    // Audio listo
    unawaited(AudioService.init());

    _initAnimaciones();
    _cargarPalabras();

    // Mantener pantalla encendida
    WakelockPlus.enable();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refuerzo para que no se apague la pantalla
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      WakelockPlus.enable();
    }
  }

  void _initAnimaciones() {
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _overlayOpacity = Tween<double>(begin: 0, end: 0.7).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );
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

    setState(() {
      _mostrandoCuentaRegresiva = true;
      _contador = 3;
    });

    await AudioService.reproducirInicio();

    for (int i = 3; i > 0; i--) {
      setState(() => _contador = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() => _contador = 0);
    await Future.delayed(const Duration(milliseconds: 400));

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // En algunos dispositivos el cambio de orientación desactiva wakelock:
    unawaited(WakelockPlus.enable());

    setState(() {
      _mostrandoCuentaRegresiva = false;
      _juegoIniciado = true;
      _palabraActual = _palabrasRestantes.first;
    });

    _iniciarTemporizador();

    _sensorService.iniciar(
      onTiltUp: _manejarAcierto,
      onTiltDown: _manejarPasar,
    );
  }

  void _iniciarTemporizador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await WakelockPlus.enable(); // refuerzo constante
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
        title: const Text("Juego en pausa",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              await SystemChrome.setPreferredOrientations(const [
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              if (mounted) Navigator.pop(context);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarOverlay(Color color) async {
    setState(() => _colorOverlay = color);
    await _overlayController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 200));
    await _overlayController.reverse();
  }

  void _manejarAcierto() async {
    if (!_juegoIniciado || _juegoTerminado || _bloqueoAccion || _juegoPausado) {
      return;
    }
    _bloqueoAccion = true;

    await AudioService.reproducirAcierto();
    await _mostrarOverlay(Colors.greenAccent.shade700);

    setState(() {
      _palabraActual?.marcarAcertada();
      _puntaje++;
      _palabrasRestantes.removeAt(0);
    });

    await Future.delayed(const Duration(milliseconds: 350));
    _siguientePalabra();
    _bloqueoAccion = false;
  }

  void _manejarPasar() async {
    if (!_juegoIniciado || _juegoTerminado || _bloqueoAccion || _juegoPausado) {
      return;
    }
    _bloqueoAccion = true;

    await AudioService.reproducirPasar();
    await _mostrarOverlay(Colors.redAccent.shade700);

    setState(() => _palabrasRestantes.removeAt(0));
    await Future.delayed(const Duration(milliseconds: 350));
    _siguientePalabra();
    _bloqueoAccion = false;
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
    await AudioService.reproducirTiempoAgotado();

    await WakelockPlus.disable();

    setState(() => _juegoTerminado = true);

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 400), () {
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sensorService.dispose();
    _overlayController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_juegoIniciado) _buildPantallaJuego() else _buildPantallaInicio(),
          if (_mostrandoCuentaRegresiva) _buildCuentaRegresiva(),
        ],
      ),
    );
  }

  // ---------- INICIO ----------
  Widget _buildPantallaInicio() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_fondoOscuro, _fondoOscuro2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.categoria.icono, style: const TextStyle(fontSize: 100)),
            const SizedBox(height: 20),
            Text(
              widget.categoria.nombre,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _iniciarJuego,
              style: ElevatedButton.styleFrom(
                backgroundColor: _fondoOscuro2,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Comenzar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- JUEGO ----------
  Widget _buildPantallaJuego() {
    return Stack(
      children: [
        // Fondo
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_fondoOscuro, _fondoOscuro2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Imagen palabra
        Positioned.fill(child: _buildBackground()),

        // Overlay animado
        AnimatedBuilder(
          animation: _overlayController,
          builder: (context, _) => Container(
              color: _colorOverlay.withOpacity(_overlayOpacity.value)),
        ),

        SafeArea(
          child: Stack(
            children: [
              // Palabra centrada arriba
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildHUDSuperior(),
                  const SizedBox(height: 10),
                  _buildPalabraSuperior(),
                  const Spacer(),
                ],
              ),

              // Reloj centrado abajo
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: _glassCapsule(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    borderRadius: 25,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_rounded, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          "$_segundosRestantes",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHUDSuperior() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Puntaje a la izquierda
          _glassCapsule(
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  "$_puntaje",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Botón pausa a la derecha
          _glassIconButton(
            icon: Icons.pause_rounded,
            onTap: _pausarJuego,
          ),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _glassCapsule(
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  "$_segundosRestantes",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _glassCapsule(
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      "$_puntaje",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _glassIconButton(
                icon: Icons.pause_rounded,
                onTap: _pausarJuego,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPalabraSuperior() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: _glassCapsule(
          key: ValueKey(_palabraActual?.texto ?? "_"),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          borderRadius: 22,
          child: Text(
            _palabraActual?.texto ?? "...",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                    blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final img = _palabraActual?.imagenUrl;
    if (img == null || img.isEmpty) {
      return Container(color: widget.categoria.color.withOpacity(0.25));
    }
    return Image.asset(
      img,
      fit: BoxFit.contain, // no deforma, deja laterales con gradiente
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
    );
  }

  // ---------- Cuenta regresiva ----------
  Widget _buildCuentaRegresiva() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
            child: child,
          ),
          child: _contador > 0
              ? Text(
                  '$_contador',
                  key: ValueKey<int>(_contador),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 150,
                      fontWeight: FontWeight.bold),
                )
              : const Text(
                  '¡YA!',
                  key: ValueKey<String>('YA'),
                  style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 130,
                      fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // ---------- Helpers visuales ----------
  Widget _glassCapsule({
    Key? key,
    required Widget child,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    double borderRadius = 16,
  }) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _fondoOscuro2.withOpacity(0.85),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: _bordeAcento.withOpacity(0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _fondoOscuro2.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _bordeAcento.withOpacity(0.8), width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
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
}
