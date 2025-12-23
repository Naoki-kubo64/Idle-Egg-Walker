/// ゲームバランスに関する定数
class GameConstants {
  GameConstants._();

  // === EXP関連 ===
  /// タップ1回あたりのEXP
  static const double expPerTap = 1.0;

  /// 歩数1歩あたりのEXP
  static const double expPerStep = 10.0;

  /// 放置収益の基本レート（1秒あたり）
  static const double baseAutoExpPerSecond = 0.1;

  // === 進化閾値 ===
  /// 卵から幼体への進化に必要なEXP
  /// 卵から幼体への進化に必要なEXP (初期HP)
  static const double expToHatch = 100.0;

  /// 幼体から成長中への進化に必要なEXP
  static const double expToTeen = 500.0;

  /// 成長中から成体への進化に必要なEXP
  static const double expToAdult = 2000.0;

  // === 自動収益ボーナス ===
  /// おともだち1体あたりの自動EXP倍率
  static const double friendMultiplier = 0.5;

  // === アニメーション時間（ミリ秒） ===
  static const int breathingDurationMs = 2000;
  static const int bounceDurationMs = 150;
  static const int evolveDurationMs = 1500;
  static const int sparkleIntervalMs = 500;

  // === ヘルス同期 ===
  /// 歩数を取得する間隔（分）
  static const int stepSyncIntervalMinutes = 5;

  /// 過去何時間分の歩数を取得するか
  static const int stepHistoryHours = 24;
}
