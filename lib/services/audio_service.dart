import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

/// Servicio para reproducir sonidos y vibraciones
class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  /// Reproduce un sonido y vibra
  static Future<void> _reproducir(String asset, int duracionVibracion) async {
    try {
      await _player.stop(); // Detener cualquier reproducción en curso
      await _player.play(AssetSource(asset));
      await vibrar(duracion: duracionVibracion);
    } catch (e) {
      debugPrint("Error reproduciendo $asset: $e");
    }
  }

  static Future<void> reproducirAcierto() =>
      _reproducir('sounds/success.mp3', 100);

  static Future<void> reproducirPasar() => _reproducir('sounds/fail.wav', 50);

  static Future<void> reproducirTiempoAgotado() =>
      _reproducir('sounds/fail.wav', 500);

  /// Vibra el dispositivo
  static Future<void> vibrar({int duracion = 100}) async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: duracion);
      }
    } catch (e) {
      debugPrint("Error vibrando: $e");
    }
  }

  /// Detiene la reproducción en curso
  static Future<void> detener() async => await _player.stop();

  /// Libera recursos
  static Future<void> dispose() async => await _player.dispose();
}
