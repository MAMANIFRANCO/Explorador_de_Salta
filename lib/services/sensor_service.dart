import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Servicio para detectar movimientos del dispositivo
/// Detecta inclinación hacia arriba (acierto) o hacia abajo (pasar)
class SensorService {
  StreamSubscription? _accelerometerSubscription;

  // Callbacks para eventos
  Function()? onTiltUp;
  Function()? onTiltDown;

  // Umbrales de detección (ajustables según sensibilidad deseada)
  final double umbralArriba = 8.0; // Inclinación hacia arriba
  final double umbralAbajo = -8.0; // Inclinación hacia abajo

  // Control de cooldown para evitar detecciones múltiples
  DateTime? _ultimaDeteccion;
  final Duration cooldownDuration = Duration(milliseconds: 800);

  bool _estaActivo = false;

  /// Inicia la escucha de eventos del acelerómetro
  void iniciar({required Function() onTiltUp, required Function() onTiltDown}) {
    if (_estaActivo) return;

    this.onTiltUp = onTiltUp;
    this.onTiltDown = onTiltDown;
    _estaActivo = true;

    // Escuchar eventos del acelerómetro
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _procesarEvento(event);
      },
      onError: (error) {
        print("Error en acelerómetro: $error");
      },
    );
  }

  /// Procesa los eventos del acelerómetro
  void _procesarEvento(AccelerometerEvent event) {
    // Verificar cooldown
    if (_ultimaDeteccion != null) {
      final diferencia = DateTime.now().difference(_ultimaDeteccion!);
      if (diferencia < cooldownDuration) {
        return; // Aún en cooldown
      }
    }

    // event.y representa la inclinación vertical del dispositivo
    // Valores positivos grandes: teléfono inclinado hacia arriba
    // Valores negativos grandes: teléfono inclinado hacia abajo

    if (event.y > umbralArriba) {
      // Inclinación hacia arriba - Acierto
      _ultimaDeteccion = DateTime.now();
      onTiltUp?.call();
    } else if (event.y < umbralAbajo) {
      // Inclinación hacia abajo - Pasar
      _ultimaDeteccion = DateTime.now();
      onTiltDown?.call();
    }
  }

  /// Detiene la escucha del acelerómetro
  void detener() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _estaActivo = false;
    _ultimaDeteccion = null;
  }

  /// Limpia recursos
  void dispose() {
    detener();
  }
}
