import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static AudioPlayer? _player;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized && _player != null) return;

    _player = AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.stop);

    await _player!.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        isSpeakerphoneOn: true,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ));

    _initialized = true;
  }

  static Future<void> _play(String asset, {bool success = true}) async {
    try {
      await init();
      await _player!.stop();
      // ✅ se usa directamente el nombre del archivo, no la lista
      await _player!.play(AssetSource(asset.replaceFirst('assets/', '')));
      await vibrar(success: success);
    } catch (e) {
      debugPrint("Error al reproducir $asset: $e");
    }
  }

  static Future<void> reproducirInicio() async =>
      _play('assets/sounds/inicio.mp3', success: true);

  static Future<void> reproducirAcierto() async =>
      _play('assets/sounds/success.mp3', success: true);

  static Future<void> reproducirPasar() async =>
      _play('assets/sounds/fail.wav', success: false);

  static Future<void> reproducirTiempoAgotado() async =>
      _play('assets/sounds/fail.wav', success: false);

  static Future<void> vibrar({bool success = true}) async {
    try {
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(success ? FeedbackType.success : FeedbackType.error);
      }
    } catch (e) {
      debugPrint("Error al vibrar: $e");
    }
  }

  static Future<void> detener() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _initialized = false;
  }
}
