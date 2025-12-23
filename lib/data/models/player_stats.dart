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

    /// 図鑑で発見済みのモンスターIDリスト（旧仕様・互換性維持）
    @Default([]) List<int> discoveredMonsterIds,

    /// 詳細な図鑑データ
    /// Key: "{id}_{stageName}" (例: "1_baby")
    /// Value: 最高レアリティ (1-5)
    @Default({}) Map<String, int> collectionCatalog,

    /// 最後に歩数を同期した時刻
    DateTime? lastStepSync,

    /// ゲーム開始日時
    DateTime? gameStartedAt,

    /// 最後にプレイした日時
    /// 最後にプレイした日時
    DateTime? lastPlayedAt,

    // === 健康管理データ ===

    /// 身長(cm) - カロリー計算用
    @Default(160.0) double heightCm,

    /// 体重(kg) - カロリー計算用
    @Default(50.0) double weightKg,

    /// 1日の目標歩数
    @Default(8000) int dailyStepGoal,

    // === 通貨・アップグレード ===
    /// 所持金 (Gold)
    @Default(0) int gold,

    /// 攻撃力アップグレードレベル（Lv1 = 1.0倍, Lv2 = 1.1倍...）
    @Default(1) int attackUpgradeLevel,

    /// タップ攻撃力アップグレードレベル
    @Default(1) int tapUpgradeLevel,

    /// 歩数ブースト終了時刻
    DateTime? stepBoostEndTime,
  }) = _PlayerStats;

  factory PlayerStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatsFromJson(json);

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

  /// おともだちの総攻撃力（タップ時の加算値）
  int get totalAttackPower {
    if (friends.isEmpty) return 0;
    final basePower = friends.fold(
      0,
      (sum, monster) => sum + monster.attackPower,
    );
    // アップグレード補正: Lv1で1.0倍, レベルアップごとに+10%
    final multiplier = 1.0 + (attackUpgradeLevel - 1) * 0.1;
    return (basePower * multiplier).toInt();
  }

  /// 現在のモンスターが卵かどうか
  bool get hasEgg => currentMonster?.isEgg ?? false;

  /// 現在育成中かどうか
  bool get isRaising => currentMonster != null;

  /// 消費カロリー計算 (簡易METs法)
  /// 歩行のMETsを3.0と仮定
  /// 1歩あたり約0.0007kcal/kgと仮定して計算
  double get totalCaloriesBurned {
    // 係数: 0.0008 kcal/step/kg ぐらいが目安 (歩幅70cmの場合)
    // ここでは少し多めに 0.001 * 体重 * 歩数 とする（ゲーム的満足感のため）
    const kcalPerStepPerKg = 0.001;
    return totalSteps * weightKg * kcalPerStepPerKg;
  }
}
