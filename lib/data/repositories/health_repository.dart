import 'package:flutter/foundation.dart';
import '../../services/log_service.dart';

import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

/// ヘルスケアデータ（歩数）を管理するリポジトリ
///
/// HealthKit (iOS) / Health Connect (Android) と連携し、
/// 歩数を取得する責務を持つ。
class HealthRepository {
  final Health _health = Health();

  // 取得したいデータタイプ
  // AndroidではHealth Connect (READ_STEPS) と、
  // Legacy Google Fit (STEPS) の両方が考慮される場合がある
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    // HealthDataType.TOTAL_CALORIES_BURNED, // 一旦外してStepのみに集中
  ];

  /// ヘルスケアへのアクセス権限をリクエスト
  Future<bool> requestPermissions() async {
    // Webの場合は非対応
    if (kIsWeb) return false;

    // Android 10以上の場合の追加権限チェック
    if (Platform.isAndroid) {
      final activityPerm = await ph.Permission.activityRecognition.request();
      if (!activityPerm.isGranted) {
        appLog('Activity Recognition Permission Denied');
        return false;
      }
    }

    try {
      // Health Connectの設定 (Android)
      // READ_WRITE 両方を要求してみる（ダイアログ表示のトリガーを確実にするため）
      bool requested = await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ_WRITE],
      );
      appLog('Health Authorization Requested: Result=$requested');
      return requested;
    } catch (e) {
      appLog('Health Auth Error: $e');
      return false;
    }
  }

  /// アプリ設定画面を開く (権限が永続的に拒否されている場合など)
  Future<bool> openDeviceSettings() async {
    return await ph.openAppSettings();
  }

  /// 権限が許可されているか確認
  Future<bool> hasPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      // SDK Check
      final status = await getHealthConnectSdkStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        appLog('Health Connect SDK not available: $status');
        return false;
      }

      // Activity Recognition Check
      final activityStatus = await ph.Permission.activityRecognition.status;
      if (!activityStatus.isGranted) {
        appLog('Activity Recognition not granted: $activityStatus');
        return false;
      }
    }

    final has = await _health.hasPermissions(_types) ?? false;
    appLog('Health hasPermissions check: $has (Types: $_types)');
    return has;
  }

  /// 指定された期間の合計歩数を取得
  ///
  /// [start] から [end] までの歩数を返す
  Future<int> getSteps(DateTime start, DateTime end) async {
    // Webの場合は非対応
    if (kIsWeb) return 0;

    try {
      // 権限確認
      bool hasPermission = await _health.hasPermissions(_types) ?? false;
      if (!hasPermission) {
        appLog('Health: No Permission');
        // 権限がない場合でも、実際にリクエストして確認する手もあるが、
        // ここでは0を返す
        return 0;
      }

      // getTotalStepsInIntervalは便利だが、うまく動作しない場合があるため
      // 生データを取得して自分で計算する方法に切り替えることも検討
      // まずは getTotalStepsInInterval を試す
      int? steps = await _health.getTotalStepsInInterval(start, end);

      appLog('Health: Steps from $start to $end = $steps');

      return steps ?? 0;
    } catch (e) {
      appLog('Health: Error fetching steps: $e');
      return 0;
    }
  }

  /// バックグラウンド復帰時の差分歩数を計算
  ///
  /// 前回保存した時刻から現在までの歩数を取得する
  Future<int> getStepsSinceLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncIso = prefs.getString('last_step_sync_time');

    final now = DateTime.now();

    // 初回起動時などは現在時刻を保存して終了
    if (lastSyncIso == null) {
      await saveLastSyncTime(now);
      return 0;
    }

    final lastSync = DateTime.parse(lastSyncIso);

    // 未来の日時が保存されていた場合のガード
    if (lastSync.isAfter(now)) {
      await saveLastSyncTime(now);
      return 0;
    }

    // 歩数取得
    final steps = await getSteps(lastSync, now);

    // 同期時刻を更新（成功時のみ）
    if (steps > 0) {
      await saveLastSyncTime(now);
    }

    return steps;
  }

  /// Health Connectのインストール
  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
  }

  /// Health Connect SDKの状態確認
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _health.getHealthConnectSdkStatus();
    } catch (e) {
      appLog('Health Status Check Error: $e');
      return HealthConnectSdkStatus.sdkUnavailable;
    }
  }

  /// 最終同期時刻を保存
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_step_sync_time', time.toIso8601String());
  }
}
