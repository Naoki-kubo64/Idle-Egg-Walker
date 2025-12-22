import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/monster.dart';
import '../../data/models/player_stats.dart';
import '../../data/repositories/health_repository.dart';
import '../../core/constants/game_constants.dart';
import '../../core/constants/gen_assets.dart';

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
    // 起動時の同期
    await syncSteps();
  }

  /// アプリ復帰時に呼び出されるメソッド
  Future<int> onAppResume() async {
    return await syncSteps();
  }

  /// 歩数を同期し、変換したExpを加算する
  /// 加算されたExp量を返す
  Future<int> syncSteps() async {
    final steps = await _healthRepository.getStepsSinceLastSync();
    if (steps > 0) {
      addSteps(steps);
      final exp = (steps * GameConstants.expPerStep).toInt();
      return exp; // UI側でダイアログ表示に使用
    }
    return 0;
  }

  /// 自動EXP獲得タイマーを開始
  void _startAutoExpTimer() {
    _autoExpTimer?.cancel();
    _autoExpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _addAutoExp();
    });
  }

  /// 1秒ごとの自動EXP加算処理
  void _addAutoExp() {
    final currentState = state;
    
    // 基本の自動EXP + おともだちボーナス
    double autoExp = GameConstants.baseAutoExpPerSecond;
    autoExp += currentState.autoExpPerSecond;
    
    if (autoExp > 0) {
      _addExp(autoExp);
    }
  }

  /// タップ時の処理
  void onTap() {
    final newStats = state.copyWith(
      totalTaps: state.totalTaps + 1,
    );
    state = newStats;
    
    _addExp(GameConstants.expPerTap);
  }

  /// 歩数を追加（ヘルスパッケージから呼ばれる）
  void addSteps(int steps) {
    if (steps <= 0) return;
    
    final expFromSteps = steps * GameConstants.expPerStep;
    
    state = state.copyWith(
      totalSteps: state.totalSteps + steps,
      lastStepSync: DateTime.now(),
    );
    
    _addExp(expFromSteps);
  }

  /// EXPを加算し、進化チェックを行う
  void _addExp(double amount) {
    final newExp = state.currentExp + amount;
    final newTotalExp = state.totalExpEarned + amount;
    
    state = state.copyWith(
      currentExp: newExp,
      totalExpEarned: newTotalExp,
      lastPlayedAt: DateTime.now(),
    );
    
    // 進化チェック
    _checkEvolution();
  }

  /// 進化条件をチェック
  void _checkEvolution() {
    final monster = state.currentMonster;
    if (monster == null) return;
    
    final threshold = _getEvolutionThreshold(monster.stage);
    if (threshold == null) return; // 最終進化済み
    
    if (state.currentExp >= threshold) {
      evolve();
    }
  }

  /// 進化閾値を取得
  double? _getEvolutionThreshold(EvolutionStage stage) {
    return switch (stage) {
      EvolutionStage.egg => GameConstants.expToHatch,
      EvolutionStage.baby => GameConstants.expToTeen,
      EvolutionStage.teen => GameConstants.expToAdult,
      EvolutionStage.adult => null, // 最終進化
    };
  }

  /// 進化を実行
  void evolve() {
    final monster = state.currentMonster;
    if (monster == null) return;
    
    final nextStage = monster.nextStage;
    if (nextStage == null) {
      // 最終進化完了 → おともだちに追加して新しい卵を生成
      _completeFriend();
      return;
    }
    
    // 卵から孵化する場合、ランダムなモンスターを決定
    Monster evolvedMonster;
    if (monster.isEgg) {
      evolvedMonster = _hatchEgg();
    } else {
      // 既存モンスターの進化
      evolvedMonster = monster.copyWith(
        stage: nextStage,
        expProductionRate: _calculateExpRate(nextStage, monster.rarity),
      );
    }
    
    // 図鑑に登録
    final discoveredIds = List<int>.from(state.discoveredMonsterIds);
    if (!discoveredIds.contains(evolvedMonster.id)) {
      discoveredIds.add(evolvedMonster.id);
    }
    
    state = state.copyWith(
      currentExp: 0.0, // EXPリセット
      currentMonster: evolvedMonster,
      discoveredMonsterIds: discoveredIds,
    );
  }

  /// 卵を孵化させてランダムなモンスターを生成
  Monster _hatchEgg() {
    // ランダムなモンスターIDを選択（1-totalMonstersの範囲で）
    final monsterId = _random.nextInt(GenAssets.totalMonsters) + 1;
    
    // レアリティを決定（加重ランダム）
    final rarity = _determineRarity();
    
    // モンスター名を生成（後で本格的な名前リストに置き換え）
    final name = _generateMonsterName(monsterId, rarity);
    
    return Monster(
      id: monsterId,
      name: name,
      stage: EvolutionStage.baby,
      rarity: rarity,
      expProductionRate: _calculateExpRate(EvolutionStage.baby, rarity),
      isDiscovered: true,
      obtainedAt: DateTime.now(),
      description: '奇跡的に生まれた、${AppTheme.getRarityName(rarity)}ランクのモンスター。',
    );
  }

  /// レアリティを決定（加重ランダム）
  int _determineRarity() {
    final roll = _random.nextDouble() * 100;
    
    if (roll < 50) return 1;      // 50% - ノーマル
    if (roll < 80) return 2;      // 30% - レア
    if (roll < 95) return 3;      // 15% - スーパーレア
    if (roll < 99) return 4;      //  4% - ウルトラレア
    return 5;                      //  1% - レジェンド
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

  /// おともだち追加完了処理
  void _completeFriend() {
    final monster = state.currentMonster;
    if (monster == null) return;
    
    // おともだちリストに追加
    final friends = List<Monster>.from(state.friends);
    friends.add(monster);
    
    // 新しい卵を生成
    final newEgg = _createNewEgg();
    
    state = state.copyWith(
      currentExp: 0.0,
      currentMonster: newEgg,
      friends: friends,
    );
  }

  /// 新しい卵を生成
  Monster _createNewEgg() {
    return const Monster(
      id: 0, // 卵は特別なID
      name: 'たまご',
      stage: EvolutionStage.egg,
    );
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
final gameProvider = NotifierProvider<GameNotifier, PlayerStats>(GameNotifier.new);
