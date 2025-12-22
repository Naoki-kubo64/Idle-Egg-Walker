import 'package:freezed_annotation/freezed_annotation.dart';
import 'monster.dart';

part 'player_stats.freezed.dart';
part 'player_stats.g.dart';

/// プレイヤーの統計情報
@freezed
class PlayerStats with _$PlayerStats {
  const PlayerStats._();
  
  const factory PlayerStats({
    /// 現在のEXP（double型で精密管理）
    @Default(0.0) double currentExp,
    
    /// 累計獲得EXP
    @Default(0.0) double totalExpEarned,
    
    /// 累計タップ数
    @Default(0) int totalTaps,
    
    /// 累計歩数（アプリ内でカウント）
    @Default(0) int totalSteps,
    
    /// 現在育成中のモンスター
    Monster? currentMonster,
    
    /// おともだち（育成完了したモンスター）リスト
    @Default([]) List<Monster> friends,
    
    /// 図鑑で発見済みのモンスターIDリスト
    @Default([]) List<int> discoveredMonsterIds,
    
    /// 最後に歩数を同期した時刻
    DateTime? lastStepSync,
    
    /// ゲーム開始日時
    DateTime? gameStartedAt,
    
    /// 最後にプレイした日時
    DateTime? lastPlayedAt,
  }) = _PlayerStats;

  factory PlayerStats.fromJson(Map<String, dynamic> json) => _$PlayerStatsFromJson(json);

  /// おともだちの数
  int get friendCount => friends.length;

  /// 図鑑の発見率（パーセント）
  double get discoveryRate {
    // TODO: 全モンスター数を定数から取得
    const totalMonsters = 50;
    return (discoveredMonsterIds.length / totalMonsters) * 100;
  }

  /// 1秒あたりの自動EXP産出量（おともだちの合計）
  double get autoExpPerSecond {
    if (friends.isEmpty) return 0.0;
    return friends.fold(0.0, (sum, monster) => sum + monster.expProductionRate);
  }

  /// 現在のモンスターが卵かどうか
  bool get hasEgg => currentMonster?.isEgg ?? false;

  /// 現在育成中かどうか
  bool get isRaising => currentMonster != null;
}
