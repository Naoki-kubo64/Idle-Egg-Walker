import 'package:flutter/foundation.dart' show kIsWeb; // 追加
import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ヘルスケアデータ（歩数）を管理するリポジトリ
///
/// HealthKit (iOS) / Health Connect (Android) と連携し、
/// 歩数を取得する責務を持つ。
class HealthRepository {
  final Health _health = Health();

  // 取得したいデータタイプ
  static const List<HealthDataType> _types = [HealthDataType.STEPS];

  /// ヘルスケアへのアクセス権限をリクエスト
  Future<bool> requestPermissions() async {
    // Webの場合は非対応
    if (kIsWeb) return false;

    // Android 10以上の場合の追加権限チェック
    if (Platform.isAndroid) {
      final activityPerm = await Permission.activityRecognition.request();
      if (!activityPerm.isGranted) return false;
    }

    try {
      // 権限リクエスト
      bool requested = await _health.requestAuthorization(_types);
      return requested;
    } catch (e) {
      // エラーハンドリング（シミュレーターなど）
      return false;
    }
  }

  /// 指定された期間の合計歩数を取得
  ///
  /// [start] から [end] までの歩数を返す
  Future<int> getSteps(DateTime start, DateTime end) async {
    // Webの場合は非対応
    if (kIsWeb) return 0;

    try {
      // 権限がない場合は0を返す
      // ignore: unused_local_variable
      bool hasPermission = await _health.hasPermissions(_types) ?? false;

      // 注意: hasPermissionsは信頼性が低い場合があるため、
      // 実際にデータを取得してみて例外が出ないかで判断することも多いが、
      // ここでは簡易的にgetTotalStepsInIntervalを使用

      int? steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      // 取得失敗時
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

  /// 最終同期時刻を保存
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_step_sync_time', time.toIso8601String());
  }
}
