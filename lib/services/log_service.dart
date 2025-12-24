import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMsg = '[$timestamp] $message';
    _logs.add(logMsg);
    debugPrint(logMsg); // コンソールにも出す

    // 古いログを削除 (最大1000行)
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }

  void clear() {
    _logs.clear();
  }
}

// グローバルなヘルパー関数
void appLog(String message) {
  LogService().log(message);
}
