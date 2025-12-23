import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/monster.dart';
import '../../data/models/player_stats.dart';
import '../../data/repositories/health_repository.dart';
import '../../core/constants/game_constants.dart';
import '../../core/constants/gen_assets.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sound_manager.dart'; // 追加
import '../../services/notification_service.dart'; // 追加

/// ゲーム状態を管理するNotifier
class GameNotifier extends Notifier<PlayerStats> {
  Timer? _autoExpTimer;
  final Random _random = Random();
  final HealthRepository _healthRepository = HealthRepository();

  @override
  PlayerStats build() {
    // dispose時にタイマーをキャンセル
    ref.onDispose(() {
      _autoExpTimer?.cancel();
    });

    // 初期状態：新しい卵を持った状態でスタート
    final initialEgg = _createNewEgg();

    // 自動EXP獲得タイマーを開始
    _startAutoExpTimer();

    // ヘルスケア連携初期化（非同期で実行）
    _initHealth();

    return PlayerStats(
      currentMonster: initialEgg,
      gameStartedAt: DateTime.now(),
      lastPlayedAt: DateTime.now(),
      // 開発用の初期データ（図鑑テスト用）
      discoveredMonsterIds: [],
    );
  }

  Future<void> _initHealth() async {
    // 権限リクエスト
    await _healthRepository.requestPermissions();
    // 起動時の同期（歩数＆時間経過）
    await syncSteps();
    _calculateOfflineDamage();
  }

  /// アプリ復帰時に呼び出されるメソッド
  /// 獲得した総EXP（ダメージ）を返す
  Future<double> onAppResume() async {
    final damageFromSteps = await syncSteps();
    final damageFromTime = _calculateOfflineDamage();

    return damageFromSteps + damageFromTime;
  }

  /// 歩数を同期し、変換したExpを加算する
  /// 加算されたダメージ量を返す
  Future<double> syncSteps() async {
    final steps = await _healthRepository.getStepsSinceLastSync();
    if (steps > 0) {
      addSteps(steps);
      return steps * GameConstants.expPerStep;
    }
    return 0.0;
  }

  /// 放置時間（オフライン）分のダメージを計算・加算
  double _calculateOfflineDamage() {
    final now = DateTime.now();
    final last = state.lastPlayedAt ?? now;
    final diffInSeconds = now.difference(last).inSeconds;

    if (diffInSeconds > 0) {
      // 平均秒間ダメージ（現在の攻撃力ベース）
      // ※厳密には放置中に進化したりすると効率が変わるが、簡易的に現在の攻撃力で計算
      final outputPerSec = state.totalAttackPower.toDouble() * 0.5;
      final damage = diffInSeconds * outputPerSec;

      if (damage > 0) {
        _addDamageToEgg(damage);
        return damage;
      }
    }
    return 0.0;
  }

  void _startAutoExpTimer() {
    _autoExpTimer?.cancel();
    _autoExpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _addAutoExp();
    });
  }

  // 秒間の自動ダメージ（おともだち効果）& ゴールド獲得
  void _addAutoExp() {
    final damage = state.totalAttackPower.toDouble() * 0.5; // 1秒あたり攻撃力の50%

    // ゴールド獲得: おともだち1体につき1G
    final goldEarned = state.friendCount;

    if (damage > 0 || goldEarned > 0) {
      if (damage > 0) {
        _addDamageToEgg(damage);
      }
      if (goldEarned > 0) {
        state = state.copyWith(gold: state.gold + goldEarned);
      }
    }
  }

  /// タップ時の処理：卵へのダメージ
  void onTap() {
    SoundManager().playTap(); // SE
    // タップ効率: Lv1で1.0倍, Lv2で1.05倍...
    final tapMultiplier = 1.0 + (state.tapUpgradeLevel - 1) * 0.05;
    final baseTapExp = GameConstants.expPerTap * tapMultiplier;

    // 卵への基本ダメージ + おともだち総攻撃力
    final damage = baseTapExp + state.totalAttackPower;

    state = state.copyWith(totalTaps: state.totalTaps + 1);
    _addDamageToEgg(damage);
  }

  /// 歩数を追加（おともだち育成 -> 卵割りパワーに変更）
  void addSteps(int steps) {
    if (steps <= 0) return;

    // 歩数ブースト確認 (現在時刻が終了時刻より前なら有効)
    final now = DateTime.now();
    final isBoostActive =
        state.stepBoostEndTime != null && state.stepBoostEndTime!.isAfter(now);

    // ブースト中は2倍
    final multiplier = isBoostActive ? 2.0 : 1.0;

    // UI表示用に歩数Expを加算
    final expFromSteps = steps * GameConstants.expPerStep * multiplier;

    state = state.copyWith(
      totalSteps: state.totalSteps + steps,
      lastStepSync: now,
    );

    // 歩数も卵へのダメージとして扱う
    _addDamageToEgg(expFromSteps);
  }

  // === アップグレード関連 ===

  // === プロフィール更新 ===
  /// 身体情報を更新
  void updateBodyProfile({
    double? height,
    double? weight,
    int? age,
    int? dailyGoal,
  }) {
    state = state.copyWith(
      heightCm: height ?? state.heightCm,
      weightKg: weight ?? state.weightKg,
      age: age ?? state.age,
      dailyStepGoal: dailyGoal ?? state.dailyStepGoal,
    );
  }

  /// 攻撃力アップグレードのコスト計算
  int get attackUpgradeCost {
    // 基本100G, レベルごとに1.8倍 (急上昇)
    return (100 * pow(1.8, state.attackUpgradeLevel - 1)).toInt();
  }

  /// タップ効率アップグレードのコスト計算
  int get tapUpgradeCost {
    // 基本200G, レベルごとに1.8倍
    return (200 * pow(1.8, state.tapUpgradeLevel - 1)).toInt();
  }

  /// 歩数ブースト(30分)のコスト
  int get stepBoostCost => 3000;

  /// 攻撃力アップグレード購入
  bool purchaseAttackUpgrade() {
    final cost = attackUpgradeCost;
    if (state.gold >= cost) {
      state = state.copyWith(
        gold: state.gold - cost,
        attackUpgradeLevel: state.attackUpgradeLevel + 1,
      );
      SoundManager().playDecide(); // SE
      return true;
    }
    return false;
  }

  /// タップ効率アップグレード購入
  bool purchaseTapUpgrade() {
    final cost = tapUpgradeCost;
    if (state.gold >= cost) {
      state = state.copyWith(
        gold: state.gold - cost,
        tapUpgradeLevel: state.tapUpgradeLevel + 1,
      );
      SoundManager().playDecide(); // SE
      return true;
    }
    return false;
  }

  /// 歩数ブースト購入（30分延長）
  bool purchaseStepBoost() {
    final cost = stepBoostCost;
    if (state.gold >= cost) {
      final now = DateTime.now();
      // 現在ブースト中ならその終了時刻から、そうでなければ現在から30分追加
      final currentEndTime =
          (state.stepBoostEndTime != null &&
                  state.stepBoostEndTime!.isAfter(now))
              ? state.stepBoostEndTime!
              : now;

      final newEndTime = currentEndTime.add(const Duration(minutes: 30));

      state = state.copyWith(
        gold: state.gold - cost,
        stepBoostEndTime: newEndTime,
      );
      SoundManager().playDecide(); // SE

      // 通知スケジュール (Webスタブではログのみ)
      NotificationService().scheduleNotification(
        id: 100,
        title: 'ブースト終了',
        body: '歩数ブーストの効果が終了しました！',
        scheduledDate: newEndTime,
      );

      return true;
    }
    return false;
  }

  /// 卵の孵化処理（ガチャ＆リセット）
  void _hatchEgg() {
    // 1. ガチャでモンスター生成
    final newMonster = _generateRandomMonster();

    // 2. おともだちリストに追加
    final updatedFriends = List<Monster>.from(state.friends)..add(newMonster);

    // 3. 図鑑更新
    final discoveredIds = List<int>.from(state.discoveredMonsterIds);
    if (!discoveredIds.contains(newMonster.id)) {
      discoveredIds.add(newMonster.id);
    }

    // 4. 図鑑更新 (詳細データ)
    final catalog = Map<String, int>.from(state.collectionCatalog);
    final key = '${newMonster.id}_${newMonster.stage.name}';
    final currentRarity = catalog[key] ?? 0;

    // 現在より高いレアリティなら更新、または新規登録
    if (newMonster.rarity > currentRarity) {
      catalog[key] = newMonster.rarity;
    }

    // 5. 新しい卵をセット (ダメージリセット)
    SoundManager().playFanfare(); // SE
    state = state.copyWith(
      currentExp: 0.0,
      currentMonster: _createNewEgg(),
      friends: updatedFriends,
      discoveredMonsterIds: discoveredIds,
      collectionCatalog: catalog,
      // gold, upgradeLevel等は維持
    );
  }

  /// ガチャ確率に基づいてランダムなモンスターを生成
  Monster _generateRandomMonster() {
    // 利用可能なIDリストからランダムに選択
    final index = _random.nextInt(GenAssets.availableMonsterIds.length);
    final monsterId = GenAssets.availableMonsterIds[index];

    final rarity = _determineRarity();
    final stage = _determineStage(rarity); // レアリティに応じて進化段階も決定
    final name = _generateMonsterName(monsterId, rarity);

    return Monster(
      id: monsterId,
      name: name,
      stage: stage,
      rarity: rarity,
      expProductionRate: 0, // 未使用
      attackPower: _calculateAttackPower(stage, rarity),
      accumulatedSteps: 0,
      isDiscovered: true,
      obtainedAt: DateTime.now(),
      description: '奇跡的に生まれた、${AppTheme.getRarityName(rarity)}ランクのモンスター。',
    );
  }

  /// 進化段階（ランク）を決定
  EvolutionStage _determineStage(int rarity) {
    // レアリティが高いほど、最初から進化している確率を上げるなどの調整も可能
    final roll = _random.nextDouble() * 100;

    // 成体(Adult): 5%
    if (roll < 5) return EvolutionStage.adult;
    // 成長体(Teen): 25%
    if (roll < 30) return EvolutionStage.teen;
    // 幼体(Baby): 70%
    return EvolutionStage.baby;
  }

  /// レアリティを決定（加重ランダム）
  int _determineRarity() {
    final roll = _random.nextDouble() * 100;

    if (roll < 50) return 1; // 50% - ノーマル
    if (roll < 80) return 2; // 30% - レア
    if (roll < 95) return 3; // 15% - スーパーレア
    if (roll < 99) return 4; //  4% - ウルトラレア
    return 5; //  1% - レジェンド
  }

  /// モンスター名を生成
  String _generateMonsterName(int id, int rarity) {
    final species = _getSpeciesName(id);
    final prefix = _getRankPrefix(rarity);
    return '$prefix$species';
  }

  /// IDに対応する種族名を取得
  String _getSpeciesName(int id) {
    return switch (id) {
      1 => 'ドラゴン',
      2 => 'スライム',
      3 => 'ゴースト',
      4 => 'ゴーレム',
      5 => 'フェアリー',
      6 => 'ウルフ',
      7 => 'ロボ',
      8 => 'プラント',
      9 => 'バット',
      10 => 'ペンギン',
      11 => 'ミミック',
      12 => 'UFO',
      13 => 'ワイバーン',
      14 => 'スケルトン',
      15 => 'イエティ',
      16 => 'カクタス',
      17 => 'クラゲ',
      18 => 'ニンジャ',
      19 => 'サムライ',
      20 => 'ウィザード',
      21 => 'ナイト',
      22 => 'デビル',
      23 => 'フェニックス',
      24 => 'ユニコーン',
      25 => 'グリフォン',
      26 => 'クラーケン',
      27 => 'マンドラゴラ',
      28 => 'スフィンクス',
      29 => 'キマイラ',
      30 => 'ゴブリン',
      31 => 'オーク',
      32 => 'トロール',
      33 => 'サイクロプス',
      34 => 'ハーピー',
      35 => 'マーメイド',
      36 => 'ケンタウロス',
      37 => 'ミノタウロス',
      38 => 'ヴァンパイア',
      39 => 'ワーウルフ',
      40 => 'ゾンビ',
      41 => 'マミー',
      42 => 'ガーゴイル',
      43 => 'バジリスク',
      44 => 'ヒドラ',
      45 => 'ケルベロス',
      46 => 'ペガサス',
      47 => 'リヴァイアサン',
      48 => 'ベヒモス',
      49 => 'メカドラゴン',
      50 => 'キングエッグ',
      _ => '謎の未確認生物',
    };
  }

  /// レアリティに応じた接頭辞（二つ名）
  String _getRankPrefix(int rarity) {
    // 毎回ランダムだと名前が変わってしまうので、今回はランダム要素は排除し、
    // レアリティごとの固定称号にするか、あるいは生成時にランダムで決める今の仕様を維持するなら
    // 配列からランダムにとる。
    // ここではシンプルにレアリティに応じた形容詞をランダムに返す。
    final prefixes = switch (rarity) {
      5 => ['伝説の', '神話級', '最強の', '究極', '光り輝く'], // LG
      4 => ['いにしえの', '王家の', '真・', '超', 'マスター'], // UR
      3 => ['強い', '大きな', 'すごい', '怒りの', '熟練'], // SR
      2 => ['元気な', '普通の', 'ちょっといい', '野生の'], // R
      _ => ['はじめての', 'よわい', 'そこらへんの', 'ちいさな', ''], // N
    };
    return prefixes[_random.nextInt(prefixes.length)];
  }

  /// 進化段階とレアリティに応じたEXP産出量を計算
  double _calculateExpRate(EvolutionStage stage, int rarity) {
    final baseRate = switch (stage) {
      EvolutionStage.egg => 0.0,
      EvolutionStage.baby => 0.1,
      EvolutionStage.teen => 0.3,
      EvolutionStage.adult => 1.0,
    };

    // レアリティボーナス
    final rarityMultiplier = 1.0 + (rarity - 1) * 0.5;

    return baseRate * rarityMultiplier;
  }

  /// 進化段階とレアリティに応じた攻撃力を計算
  int _calculateAttackPower(EvolutionStage stage, int rarity) {
    final basePower = switch (stage) {
      EvolutionStage.egg => 0,
      EvolutionStage.baby => 1,
      EvolutionStage.teen => 2,
      EvolutionStage.adult => 5,
    };
    return basePower * rarity;
  }

  /// 新しい卵を生成
  Monster _createNewEgg() {
    return const Monster(
      id: 0, // 卵は特別なID
      name: 'たまご',
      stage: EvolutionStage.egg,
    );
  }

  /// 卵にダメージを加算
  void _addDamageToEgg(double amount) {
    if (state.currentMonster == null) return;

    final newDamage = state.currentExp + amount;
    final hatchThreshold = _getHatchThreshold();

    if (newDamage >= hatchThreshold) {
      _hatchEgg();
    } else {
      state = state.copyWith(
        currentExp: newDamage,
        lastPlayedAt: DateTime.now(),
      );
    }
  }

  /// 卵の孵化に必要なHP
  double _getHatchThreshold() {
    // おともだち数が増えるごとに難易度アップ (2次関数的増加)
    // 基本HP (100) + (おともだち数 * 500) + (おともだち数^2 * 20)
    final count = state.friends.length;
    return GameConstants.expToHatch + (count * 500.0) + (count * count * 20.0);
  }

  /// ゲームデータをリセット（デバッグ用）
  void resetGame() {
    _autoExpTimer?.cancel();
    state = PlayerStats(
      currentMonster: _createNewEgg(),
      gameStartedAt: DateTime.now(),
      lastPlayedAt: DateTime.now(),
      discoveredMonsterIds: [],
    );
    _startAutoExpTimer();
  }
}

/// ゲーム状態のプロバイダー
final gameProvider = NotifierProvider<GameNotifier, PlayerStats>(
  GameNotifier.new,
);
