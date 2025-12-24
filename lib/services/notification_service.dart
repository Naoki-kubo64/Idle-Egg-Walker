import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    debugPrint('NotificationService (Web Stub): init');
  }

  Future<bool> requestPermissions() async {
    debugPrint('NotificationService (Web Stub): requestPermissions');
    return true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('NotificationService (Web Stub): Show "$title" - "$body"');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    debugPrint(
      'NotificationService (Web Stub): Schedule "$title" at $scheduledDate',
    );
  }

  Future<void> cancelNotification(int id) async {
    debugPrint('NotificationService (Web Stub): Cancel $id');
  }

  /// 歩数ブースト終了の通知をスケジュール（スタブ）
  Future<void> scheduleBoostEndNotification(DateTime endTime) async {
    debugPrint(
      'NotificationService (Web Stub): Schedule boost notification at $endTime',
    );
  }
}
