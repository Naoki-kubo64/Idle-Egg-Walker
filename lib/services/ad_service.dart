import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart'; // debugPrint用

/// 広告サービス
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// 初期化完了フラグ
  bool _isInitialized = false;

  /// 初期化処理
  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) return; // Webでは何もしない

    await MobileAds.instance.initialize();
    _isInitialized = true;
    debugPrint('AdService: MobileAds initialized.');
  }

  /// バナー広告ID
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3172990250156448/9878666424';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOSはテスト用のまま
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 動画リワード広告ID
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3172990250156448/1147912123';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOSはテスト用のまま
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 動画広告を視聴する
  Future<bool> watchAd() async {
    if (kIsWeb) {
      // Web開発用モック
      debugPrint('AdService: Showing mock ad for Web...');
      await Future.delayed(const Duration(seconds: 3));
      return true;
    }

    if (!_isInitialized) await init();

    // リワード広告の実装
    // 簡易的にロードして表示待機
    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(
            onUserEarnedReward: (ad, reward) {
              if (!completer.isCompleted) completer.complete(true);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }
}
