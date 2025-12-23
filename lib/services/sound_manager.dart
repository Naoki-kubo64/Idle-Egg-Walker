import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 効果音・BGMを管理するクラス
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();

  // BGMの音量 (0.0 - 1.0)
  static const double _bgmVolume = 0.3;
  // SEの音量
  static const double _seVolume = 0.6;

  bool _isBgmPlaying = false;

  /// 初期化
  Future<void> init() async {
    // Webなどでユーザー操作前に再生しようとするとエラーになる場合があるため
    // ここでは準備だけ行う
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// BGM再生
  Future<void> playBgm() async {
    try {
      if (_isBgmPlaying) return;
      // assets/audio/bgm_main.mp3 をループ再生
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource('audio/bgm_main.mp3'));
      _isBgmPlaying = true;
    } catch (e) {
      debugPrint('BGM Play Error: $e');
    }
  }

  /// BGM停止
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
    } catch (e) {
      debugPrint('BGM Stop Error: $e');
    }
  }

  /// タップ音再生
  Future<void> playTap() async {
    await _playSe('audio/se_tap.mp3');
  }

  /// 決定/購入音再生
  Future<void> playDecide() async {
    await _playSe('audio/se_decide.mp3');
  }

  /// 孵化/進化音再生
  Future<void> playFanfare() async {
    await _playSe('audio/se_fanfare.mp3');
  }

  /// ゴールド獲得音
  Future<void> playCoin() async {
    // 連続再生できるようモードを調整するか、都度生成
    await _playSe('audio/se_coin.mp3');
  }

  /// SE再生共通処理
  Future<void> _playSe(String path) async {
    try {
      // SEは同時多発する可能性が高いため、都度プレイヤーを作成して破棄する
      // AudioPoolのような仕組みが理想だが、audioplayers 4.xでは都度作成が主流
      final player = AudioPlayer();
      await player.setVolume(_seVolume);

      // 再生完了後にdispose
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });

      await player.play(AssetSource(path));
    } catch (e) {
      // アセットがない場合もエラーになるが、クラッシュはさせない
      if (kDebugMode) {
        debugPrint('SE Play Error ($path): $e');
      }
    }
  }
}
