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

    /// 年齢
    @Default(30) int age,

    /// 1日の目標歩数
    @Default(8000) int dailyStepGoal,

    /// 日別歩数履歴 (yyyy-MM-dd -> steps)
    @Default({}) Map<String, int> dailyStepsHistory,

    // === 通貨・アップグレード ===
    /// 所持金 (Gold)
    @Default(0) int gold,

    /// 所持ジェム (Premium Currency)
    @Default(100) int gems,

    /// 攻撃力アップグレードレベル（Lv1 = 1.0倍, Lv2 = 1.1倍...）
    @Default(1) int attackUpgradeLevel,

    /// タップ攻撃力アップグレードレベル
    @Default(1) int tapUpgradeLevel,

    /// 最後に動画を見て攻撃力アップグレードをした時間
    DateTime? lastAdAttackUpgradeTime,

    /// 最後に動画を見てタップアップグレードをした時間
    DateTime? lastAdTapUpgradeTime,

    /// 最後に動画を見て歩数ブーストをした時間
    DateTime? lastAdStepBoostTime,

    /// 最後に動画を見てEPSブーストをした時間
    DateTime? lastAdEpsBoostTime,

    /// 歩数ブースト終了時刻
    DateTime? stepBoostEndTime,

    /// EPSブースト終了時刻
    DateTime? epsBoostEndTime,

    /// 最後に動画を見てタップブーストをした時間
    DateTime? lastAdTapBoostTime,

    /// タップブースト終了時刻
    DateTime? tapBoostEndTime,
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
  /// GameNotifier._addAutoExpのロジックと一致させる(攻撃力 * 0.5)
  double get autoExpPerSecond {
    if (friends.isEmpty) return 0.0;
    double baseEps = totalAttackPower.toDouble() * 0.5;

    // EPSブースト適用
    if (epsBoostEndTime != null && epsBoostEndTime!.isAfter(DateTime.now())) {
      baseEps *= 10;
    }

    return baseEps;
  }

  /// 現在の1タップあたりのダメージ量
  /// (基本値 * タップ倍率) + おともだち総攻撃力
  double get currentTapPower {
    // TODO: GameConstants.expPerTapを直参照するか、引数で渡すかだが、
    // ここではマジックナンバーを避けるため定数と同じ3000.0を使用するか、
    // GameNotifierと共通化するためにロジックをここに集約すべき。
    // 今回は整合性を取るため計算式を再現。
    const double baseExp = 1.0; // GameConstants.expPerTap
    final double tapMultiplier = 1.0 + (tapUpgradeLevel - 1) * 0.05;

    double power = (baseExp * tapMultiplier) + totalAttackPower;

    // タップブースト適用 (5倍)
    if (tapBoostEndTime != null && tapBoostEndTime!.isAfter(DateTime.now())) {
      power *= 5;
    }

    return power;
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

  /// 消費カロリー計算 (距離法)
  /// 歩数と身体情報から推定
  double get totalCaloriesBurned {
    // 歩幅(m)の推定 (身長 * 0.45)
    final strideM = (heightCm * 0.45) / 100.0;

    // 総歩行距離(km)
    final distanceKm = (totalSteps * strideM) / 1000.0;

    // 消費カロリー (kcal) = 距離(km) * 体重(kg) * 係数(1.05程度)
    return distanceKm * weightKg * 1.05;
  }
}
