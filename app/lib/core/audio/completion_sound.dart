import 'package:audioplayers/audioplayers.dart';

/// 待办完成时的短音效
class CompletionSound {
  CompletionSound._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> play() async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource('sounds/complete.wav'),
        volume: 0.55,
      );
    } catch (_) {
      // Web/权限等环境下播放失败时静默跳过
    }
  }
}
