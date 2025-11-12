import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

/// Servicio para detectar inclinación del dispositivo usando el acelerómetro.
/// Detecta:
/// - Boca arriba  -> onTiltUp (acierto)
/// - Boca abajo   -> onTiltDown (pasar)
class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Callbacks principales
  Function()? onTiltUp;
  Function()? onTiltDown;

  // Umbral (ajustable)
  final double threshold = 7.0;

  // Cooldown para evitar múltiples triggers seguidos
  DateTime? _ultimaDeteccion;
  final Duration cooldownDuration = const Duration(milliseconds: 900);

  bool _estaActivo = false;

  /// Inicia la escucha del acelerómetro
  void iniciar({
    required Function() onTiltUp,
    required Function() onTiltDown,
  }) {
    if (_estaActivo) return;

    this.onTiltUp = onTiltUp;
    this.onTiltDown = onTiltDown;
    _estaActivo = true;

    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) => _procesarEvento(event),
      onError: (e) => debugPrint('Error en acelerómetro: $e'),
    );
  }

  void _procesarEvento(AccelerometerEvent event) {
    // Evita múltiples detecciones en un corto lapso
    if (_ultimaDeteccion != null &&
        DateTime.now().difference(_ultimaDeteccion!) < cooldownDuration) {
      return;
    }

    final double z = event.z;

    if (z > threshold) {
      _ultimaDeteccion = DateTime.now();
      onTiltUp?.call(); // Boca arriba -> acierto
    } else if (z < -threshold) {
      _ultimaDeteccion = DateTime.now();
      onTiltDown?.call(); // Boca abajo -> pasar
    }
  }

  void detener() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _estaActivo = false;
    _ultimaDeteccion = null;
  }

  void dispose() => detener();
}
