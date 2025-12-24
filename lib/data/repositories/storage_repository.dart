import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';

class StorageRepository {
  static const String _playerStatsKey = 'player_stats';

  Future<void> savePlayerStats(PlayerStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(stats.toJson());
      await prefs.setString(_playerStatsKey, jsonString);
    } catch (e) {
      // 保存失敗時のログ出力などを検討（現状は print）
      print('Failed to save player stats: $e');
    }
  }

  Future<PlayerStats?> loadPlayerStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_playerStatsKey);
      if (jsonString != null) {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return PlayerStats.fromJson(jsonMap);
      }
    } catch (e) {
      print('Failed to load player stats: $e');
    }
    return null;
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerStatsKey);
  }
}
