import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 効果音・BGMを管理するクラス
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  // ファンファーレなど重要SE用の専用プレイヤー（連打で消されないように）
  final AudioPlayer _fanfarePlayer = AudioPlayer();

  // BGMの音量 (0.0 - 1.0)
  double _bgmVolume = 0.3;
  double get bgmVolume => _bgmVolume;

  // SEの音量
  double _seVolume = 0.6;
  double get seVolume => _seVolume;

  bool _isBgmPlaying = false;

  // SE用プレイヤーのプール（Webでのオーディオコンテキスト制限対策）
  final List<AudioPlayer> _sePool = [];
  final int _poolSize = 10;
  int _poolIndex = 0;

  /// 初期化
  Future<void> init() async {
    await _loadSettings();

    // AudioContextの設定（Androidでの安定再生のため）
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );

    // Webなどでユーザー操作前に再生しようとするとエラーになる場合があるため
    // ここでは準備だけ行う
    // Note: playBgm() 呼び出し時にも再度設定する
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

    // SEプールの初期化
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      _sePool.add(player);
    }
  }

  /// 設定読み込み
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.3;
    _seVolume = prefs.getDouble('se_volume') ?? 0.6;
  }

  /// BGM音量設定
  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_bgmVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', _bgmVolume);
  }

  /// SE音量設定
  Future<void> setSeVolume(double volume) async {
    _seVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('se_volume', _seVolume);
  }

  /// BGM再生
  Future<void> playBgm() async {
    try {
      if (_isBgmPlaying) return;
      // assets/audio/bgm_main.mp3 をループ再生
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // 再生直前に必ず設定
      await _bgmPlayer.play(AssetSource('audio/bgm_main.mp3'));
      _isBgmPlaying = true;
    } catch (e) {
      debugPrint('BGM Play Error: $e');
      _isBgmPlaying = false; // 失敗したらフラグを戻す
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

  /// ユーザーインタラクション時にBGM再生を確認・開始
  void _ensureBgmPlaying() {
    if (!_isBgmPlaying) {
      playBgm();
    }
  }

  /// タップ音再生
  Future<void> playTap() async {
    _ensureBgmPlaying(); // ユーザー操作時なのでBGM開始チャンス
    await _playSe('audio/se_tap.mp3');
  }

  /// 決定/購入音再生
  Future<void> playDecide() async {
    _ensureBgmPlaying();
    await _playSe('audio/se_decide.mp3');
  }

  /// 孵化/進化音再生
  Future<void> playFanfare() async {
    _ensureBgmPlaying();
    try {
      await _fanfarePlayer.stop(); // 既存のファンファーレがあれば止める（鳴り直し）
      await _fanfarePlayer.setVolume(_seVolume);
      await _fanfarePlayer.play(AssetSource('audio/se_fanfare.mp3'));
    } catch (e) {
      debugPrint('Fanfare Play Error: $e');
    }
  }

  /// ゴールド獲得音
  Future<void> playCoin() async {
    // 連続再生できるようモードを調整するか、都度生成
    await _playSe('audio/se_coin.mp3');
  }

  /// SE再生共通処理
  Future<void> _playSe(String path) async {
    try {
      if (_sePool.isEmpty) return;

      // プールから次のプレイヤーを取得（ラウンドロビン）
      final player = _sePool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _poolSize;

      // 既存の再生を止めて（念のため）、音量セットして再生
      // await player.stop(); // AbortError回避のため stop() は呼ばずに上書き再生を試みる
      await player.setVolume(_seVolume);

      // 再生
      if (player.state == PlayerState.playing) {
        // 再生中なら再生位置を0に戻すことでリスタート効果を狙う
        await player.seek(Duration.zero);
      }
      await player.play(AssetSource(path));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SE Play Error ($path): $e');
      }
    }
  }
}
