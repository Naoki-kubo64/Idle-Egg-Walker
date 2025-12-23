import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/monster.dart';
import '../../data/models/player_stats.dart';
import '../../data/repositories/health_repository.dart';
import '../../core/constants/game_constants.dart';
import '../../core/constants/gen_assets.dart';
import '../../core/theme/app_theme.dart'; // 追加

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

  // 秒間の自動ダメージ（おともだち効果）
  void _addAutoExp() {
    final damage = state.totalAttackPower.toDouble() * 0.5; // 1秒あたり攻撃力の50%
    if (damage > 0) {
      _addDamageToEgg(damage);
    }
  }

  /// タップ時の処理：卵へのダメージ
  void onTap() {
    // 卵への基本ダメージ(50) + おともだち総攻撃力
    final damage = 50.0 + state.totalAttackPower;

    state = state.copyWith(totalTaps: state.totalTaps + 1);
    _addDamageToEgg(damage);
  }

  /// 歩数を追加（おともだち育成 -> 卵割りパワーに変更）
  void addSteps(int steps) {
    if (steps <= 0) return;

    // UI表示用に歩数Expを加算
    final expFromSteps = steps * GameConstants.expPerStep;

    state = state.copyWith(
      totalSteps: state.totalSteps + steps,
      lastStepSync: DateTime.now(),
    );

    // 歩数も卵へのダメージとして扱う
    _addDamageToEgg(expFromSteps);
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

    // 4. 新しい卵をセット (ダメージリセット)
    state = state.copyWith(
      currentExp: 0.0,
      currentMonster: _createNewEgg(),
      friends: updatedFriends,
      discoveredMonsterIds: discoveredIds,
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
    // 仮の名前生成（後で本格的なデータに置き換え）
    final prefixes = ['もこ', 'ふわ', 'ぷに', 'きら', 'ほわ', 'ドラ', 'ピコ', 'メカ'];
    final suffixes = ['たん', 'ちゃん', 'まる', 'ぴょん', 'りん', 'ゴン', 'モン', 'エース'];

    final prefix = prefixes[id % prefixes.length];
    final suffix = suffixes[rarity - 1]; // レアリティが高いほど強そうな接尾辞にしても良い

    return '$prefix$suffix';
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
    // おともだち数が増えるごとに難易度アップ
    // 基本HP (500) + (おともだち数 * 500)
    return GameConstants.expToHatch + (state.friends.length * 500.0);
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
