import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/monster_data.dart';
import '../../data/models/monster.dart';
import '../../data/models/player_stats.dart';
import '../../data/repositories/health_repository.dart';
import 'package:health/health.dart';
import '../../core/constants/game_constants.dart';

import '../../services/sound_manager.dart';
import '../../services/notification_service.dart';
import '../../data/repositories/storage_repository.dart';
import '../../services/ad_service.dart';
import '../../services/purchase_service.dart';

/// ゲーム状態を管理するNotifier
class GameNotifier extends Notifier<PlayerStats> {
  Timer? _autoExpTimer;
  Timer? _autoSaveTimer; // オートセーブ用タイマー
  final Random _random = Random();
  final HealthRepository _healthRepository = HealthRepository();
  final StorageRepository _storageRepository = StorageRepository();
  final AdService _adService = AdService();
  final PurchaseService _purchaseService = PurchaseService();
  bool isPro = false; // Pro Subscription Status

  @override
  PlayerStats build() {
    // dispose時にタイマーをキャンセル
    ref.onDispose(() {
      _autoExpTimer?.cancel();
      _autoSaveTimer?.cancel();
      // 終了時に保存
      _storageRepository.savePlayerStats(state);
    });

    // 初期状態：新しい卵を持った状態でスタート（ロード完了までの一時的な状態）
    final initialEgg = _createNewEgg();

    // データのロードを開始
    _loadData(initialEgg);

    return PlayerStats(
      currentMonster: initialEgg,
      gameStartedAt: DateTime.now(),
      lastPlayedAt: DateTime.now(),
      discoveredMonsterIds: [],
    );
  }

  /// 保存されたデータをロードし、なければ初期化処理を行う
  Future<void> _loadData(Monster initialEgg) async {
    final loadedStats = await _storageRepository.loadPlayerStats();

    if (loadedStats != null) {
      // 基本的なロード
      state = loadedStats;
      // 最終プレイ時刻からの経過時間を計算して加算
      _calculateOfflineDamage();
    } else {
      // 初回起動時の初期化
      _initHealth();
    }

    // Pro entitlement check
    isPro = await _purchaseService.isProUser();

    // Start timers
    _startTimers();
  }

  void _startTimers() {
    _startAutoExpTimer();
    _startAutoSaveTimer();
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _save();
    });
  }

  Future<void> _save() async {
    await _storageRepository.savePlayerStats(state);
  }

  // 既存メソッド...

  Future<void> _initHealth() async {
    // 権限リクエスト
    await _healthRepository.requestPermissions();
    // 起動時の同期（歩数＆時間経過）
    await syncSteps();
  }

  /// アプリ復帰時に呼び出されるメソッド
  /// 獲得した歩数とEXPの詳細を返す
  Future<Map<String, num>> syncAndGetDetails() async {
    final steps = await _healthRepository.getStepsSinceLastSync();

    double stepExp = 0.0;
    if (steps > 0) {
      stepExp = addSteps(steps);
    }

    final timeExp = _calculateOfflineDamage();

    return {
      'steps': steps,
      'stepExp': stepExp,
      'timeExp': timeExp,
      'exp': stepExp + timeExp,
    };
  }

  /// onAppResumeは後方互換性のため残すが、syncAndGetDetailsを使う推奨
  Future<double> onAppResume() async {
    final result = await syncAndGetDetails();
    return (result['exp'] as num).toDouble();
  }

  /// 歩数を同期し、変換したExpを加算する
  /// 加算されたダメージ量を返す
  Future<double> syncSteps() async {
    final steps = await _healthRepository.getStepsSinceLastSync();
    if (steps > 0) {
      return addSteps(steps);
    }
    return 0.0;
  }

  /// アプリ一時停止（バックグラウンド移行）時に保存
  Future<void> onAppPause() async {
    await _save();
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
  /// 獲得したEXPを返す
  double addSteps(int steps) {
    if (steps <= 0) return 0.0;

    // 歩数ブースト確認 (現在時刻が終了時刻より前なら有効)
    final now = DateTime.now();
    final isBoostActive =
        state.stepBoostEndTime != null && state.stepBoostEndTime!.isAfter(now);

    // ブースト中は2倍
    final multiplier = isBoostActive ? 2.0 : 1.0;

    // UI表示用に歩数Expを加算
    final expFromSteps = steps * GameConstants.expPerStep * multiplier;

    // 日別履歴の更新
    final todayKey = now.toIso8601String().split('T')[0];
    final currentHistory = Map<String, int>.from(state.dailyStepsHistory);
    currentHistory[todayKey] = (currentHistory[todayKey] ?? 0) + steps;

    state = state.copyWith(
      totalSteps: state.totalSteps + steps,
      lastStepSync: now,
      dailyStepsHistory: currentHistory,
    );

    // 歩数も卵へのダメージとして扱う
    _addDamageToEgg(expFromSteps);

    return expFromSteps;
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
      _save(); // 重要イベントなので保存
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

      _save(); // 保存
      return true;
    }
    return false;
  }

  /// 卵の孵化処理（ガチャ＆リセット）
  void _hatchEgg() {
    // 1. ガチャでモンスター生成 (常にBabyとして生成)
    final newMonster = _generateRandomMonster();

    // 2. 図鑑更新 (合体で消える前に、生まれた瞬間のモンスターを記録)
    final discoveredIds = List<int>.from(state.discoveredMonsterIds);
    final catalog = Map<String, int>.from(state.collectionCatalog);

    // 生まれたモンスターをカタログに登録
    if (!discoveredIds.contains(newMonster.id)) {
      discoveredIds.add(newMonster.id);
    }
    final newKey = '${newMonster.id}_${newMonster.stage.name}';
    final currentRarity = catalog[newKey] ?? 0;
    if (newMonster.rarity > currentRarity) {
      catalog[newKey] = newMonster.rarity;
    }

    // 3. おともだちリストに追加 & 合体進化チェック
    var updatedFriends = List<Monster>.from(state.friends);

    // 同じ種類のBaby/Teenが2体いるかチェックして合体
    updatedFriends = _tryMergeMonsters(updatedFriends, newMonster);

    // 4. 合体後の結果もカタログに反映 (進化したモンスターなど)
    for (final friend in updatedFriends) {
      if (!discoveredIds.contains(friend.id)) {
        discoveredIds.add(friend.id);
      }
      final key = '${friend.id}_${friend.stage.name}';
      final r = catalog[key] ?? 0;
      if (friend.rarity > r) {
        catalog[key] = friend.rarity;
      }
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
    _save(); // 孵化（進化完了）時に保存
  }

  /// モンスターリストに新しいモンスターを追加し、合体進化を試みる
  List<Monster> _tryMergeMonsters(
    List<Monster> currentFriends,
    Monster newMonster,
  ) {
    // まず新しいモンスターを追加
    final friends = List<Monster>.from(currentFriends)..add(newMonster);

    // 合体ロジック: 再帰的にチェック (Babyが2体 -> Teenが2体 -> Adultになる可能性)
    bool merged;
    do {
      merged = false;
      // グループ化: IDとStageが同じものを集める
      final Map<String, List<Monster>> groups = {};
      for (var m in friends) {
        // Adultはこれ以上進化しないので対象外
        if (m.stage == EvolutionStage.adult) continue;

        final key = '${m.id}_${m.stage.name}';
        if (!groups.containsKey(key)) groups[key] = [];
        groups[key]!.add(m);
      }

      // 2体以上あるグループを探す
      for (final key in groups.keys) {
        final group = groups[key]!;
        if (group.length >= 2) {
          // 2体を取り除く
          final targets = group.take(2).toList();
          for (var t in targets) {
            friends.remove(t);
          }

          // 合体するモンスターの中で最も高いレアリティを引き継ぐ
          final maxRarity = targets.map((m) => m.rarity).reduce(max);

          // 進化した1体を追加
          final base = targets.first;
          final nextStage = base.nextStage;
          if (nextStage != null) {
            final evolvedMonster = base.copyWith(
              stage: nextStage,
              rarity: maxRarity, // 最高レアリティを引き継ぐ
              attackPower: _calculateAttackPower(nextStage, maxRarity),
              // 名前も更新が必要ならここで (例: アダルトドラゴン)
            );
            friends.add(evolvedMonster);
            merged = true;
            // ログ: 合体しました！
          }

          // リスト変更したのでループを抜けて再評価
          break;
        }
      }
    } while (merged);

    return friends;
  }

  /// ガチャ確率に基づいてランダムなモンスターを生成
  Monster _generateRandomMonster() {
    final rarity = _determineRarity();
    final stage = _determineStage();

    int monsterId;
    if (rarity == 6) {
      // USR (Ultra Super Rare) -> ID 49 (Mecha Dragon) or 50 (King Egg)
      monsterId = 49 + _random.nextInt(2);
    } else {
      // Normal to Legend -> ID 1 to 48
      // availableMonsterIdsは1..50が入っているが、ここから49,50を除外する
      // ID 1..48 の範囲でランダム
      monsterId = 1 + _random.nextInt(48);
    }

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
      description: MonsterData.getDescription(monsterId, stage),
    );
  }

  /// 初期排出ステージを決定
  EvolutionStage _determineStage() {
    final roll = _random.nextDouble() * 100;
    if (roll < 2) return EvolutionStage.adult; // 2%
    if (roll < 7) return EvolutionStage.teen; // 5% (+2=7)
    return EvolutionStage.baby; // 93%
  }

  /// レアリティを決定（加重ランダム）
  int _determineRarity() {
    final roll = _random.nextDouble() * 100;

    // N:50%, R:30%, SR:15%, UR:4%, LG:0.5%, USR:0.5%
    if (roll < 50) return 1; // 50.0% - N
    if (roll < 80) return 2; // 30.0% - R
    if (roll < 95) return 3; // 15.0% - SR
    if (roll < 99) return 4; //  4.0% - UR
    if (roll < 99.5) return 5; //  0.5% - LG
    return 6; //  0.5% - USR
  }

  /// 攻撃力の計算
  int _calculateAttackPower(EvolutionStage stage, int rarity) {
    // USR (Rarity 6) は特別扱いし、強力なステータスにする
    if (rarity == 6) {
      final basePower = switch (stage) {
        EvolutionStage.egg => 0,
        EvolutionStage.baby => 2, // 50 -> 2 (Total: 20)
        EvolutionStage.teen => 10, // 250 -> 10 (Total: 100)
        EvolutionStage.adult => 50, // 1000 -> 50 (Total: 500)
      };
      return basePower * 10; // ベース自体を高く設定したのでさらに倍率は抑えめでも強いが、要望通り強力に
    }

    final basePower = switch (stage) {
      EvolutionStage.egg => 0,
      EvolutionStage.baby => 1,
      EvolutionStage.teen => 5,
      EvolutionStage.adult => 15,
    };
    return basePower * rarity;
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
      6 => ['究極の', '最強の', '伝説を超える', '奇跡の'], // USR
      5 => ['伝説の', '神話級', '最強の', '究極', '光り輝く'], // LG
      4 => ['いにしえの', '王家の', '真・', '超', 'マスター'], // UR
      3 => ['強い', '大きな', 'すごい', '怒りの', '熟練'], // SR
      2 => ['元気な', '普通の', 'ちょっといい', '野生の'], // R
      _ => ['はじめての', 'よわい', 'そこらへんの', 'ちいさな', ''], // N
    };
    return prefixes[_random.nextInt(prefixes.length)];
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

  // === 広告関連ロジック ===

  /// 広告を見て攻撃力をアップグレード (無料 +1レベル)
  bool get canWatchAdAttackUpgrade {
    if (state.lastAdAttackUpgradeTime == null) return true;
    final diff = DateTime.now().difference(state.lastAdAttackUpgradeTime!);
    return diff.inHours >= 1;
  }

  /// 攻撃力アップグレードの広告再生残り時間
  Duration get adAttackUpgradeCooldown {
    if (state.lastAdAttackUpgradeTime == null) return Duration.zero;
    final diff = DateTime.now().difference(state.lastAdAttackUpgradeTime!);
    final remaining = const Duration(hours: 1) - diff;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 広告を見て攻撃力アップグレード (+1 Level - 無料)
  Future<bool> watchAdForAttackUpgrade() async {
    if (!canWatchAdAttackUpgrade) return false;

    // Pro User: Instant Reward
    if (isPro) {
      await Future.delayed(const Duration(milliseconds: 500)); // Mock wait
      _grantAttackUpgradeReward();
      return true;
    }

    final result = await _adService.watchAd();
    if (result) {
      _grantAttackUpgradeReward();
      return true;
    }
    return false;
  }

  void _grantAttackUpgradeReward() {
    final now = DateTime.now();
    state = state.copyWith(
      attackUpgradeLevel: state.attackUpgradeLevel + 1,
      lastAdAttackUpgradeTime: now,
    );
    SoundManager().playFanfare();
    _save();
  }

  /// タップアップグレードの広告再生残り時間
  bool get canWatchAdTapUpgrade {
    if (state.lastAdTapUpgradeTime == null) return true;
    final diff = DateTime.now().difference(state.lastAdTapUpgradeTime!);
    return diff.inHours >= 4;
  }

  /// タップアップグレードの広告再生残り時間
  Duration get adTapUpgradeCooldown {
    if (state.lastAdTapUpgradeTime == null) return Duration.zero;
    final diff = DateTime.now().difference(state.lastAdTapUpgradeTime!);
    final remaining = const Duration(hours: 4) - diff;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<bool> watchAdForTapUpgrade() async {
    if (!canWatchAdTapUpgrade) return false;

    // Pro User: Instant Reward
    if (isPro) {
      await Future.delayed(const Duration(milliseconds: 500));
      _grantTapUpgradeReward();
      return true;
    }

    final result = await _adService.watchAd();
    if (result) {
      _grantTapUpgradeReward();
      return true;
    }
    return false;
  }

  void _grantTapUpgradeReward() {
    final now = DateTime.now();
    state = state.copyWith(
      tapUpgradeLevel: state.tapUpgradeLevel + 1,
      lastAdTapUpgradeTime: now,
    );
    SoundManager().playFanfare();
    _save();
  }

  /// 歩数ブーストの広告が見られるか (24時間クールダウン)
  bool get canWatchAdStepBoost {
    if (state.lastAdStepBoostTime == null) return true;
    final diff = DateTime.now().difference(state.lastAdStepBoostTime!);
    return diff.inHours >= 24;
  }

  /// 歩数ブーストの広告再生残り時間
  Duration get adStepBoostCooldown {
    if (state.lastAdStepBoostTime == null) return Duration.zero;
    final diff = DateTime.now().difference(state.lastAdStepBoostTime!);
    final remaining = const Duration(hours: 24) - diff;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 広告を見てステップブースト (30分2倍 - 無料)
  Future<bool> watchAdForStepBoost() async {
    if (!canWatchAdStepBoost) return false;

    // Pro User: Instant Reward
    if (isPro) {
      await Future.delayed(const Duration(milliseconds: 500));
      _grantStepBoostReward();
      return true;
    }

    final result = await _adService.watchAd();
    if (result) {
      _grantStepBoostReward();
      return true;
    }
    return false;
  }

  void _grantStepBoostReward() {
    final now = DateTime.now();
    final currentEndTime = state.stepBoostEndTime ?? now;
    final startTime = currentEndTime.isAfter(now) ? currentEndTime : now;

    state = state.copyWith(
      stepBoostEndTime: startTime.add(const Duration(minutes: 30)),
      lastAdStepBoostTime: now,
    );

    SoundManager().playFanfare();
    // 通知もスケジュール
    NotificationService().scheduleBoostEndNotification(state.stepBoostEndTime!);
    _save();
  }

  // === EPS Boost (x10) Logic ===

  /// EPSブーストの広告が見られるか (3分間隔)
  bool get canWatchAdEpsBoost {
    if (state.lastAdEpsBoostTime == null) return true;
    final diff = DateTime.now().difference(state.lastAdEpsBoostTime!);
    return diff.inMinutes >= 3;
  }

  /// EPSブーストの広告再生残り時間
  Duration get adEpsBoostCooldown {
    if (state.lastAdEpsBoostTime == null) return Duration.zero;
    final diff = DateTime.now().difference(state.lastAdEpsBoostTime!);
    final remaining = const Duration(minutes: 3) - diff;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 広告を見てEPSブースト (3分間10倍 - 無料)
  Future<bool> watchAdForEpsBoost() async {
    if (!canWatchAdEpsBoost) return false;

    // Pro User: Instant Reward
    if (isPro) {
      await Future.delayed(const Duration(milliseconds: 500));
      _grantEpsBoostReward();
      return true;
    }

    final result = await _adService.watchAd();
    if (result) {
      _grantEpsBoostReward();
      return true;
    }
    return false;
  }

  void _grantEpsBoostReward() {
    final now = DateTime.now();
    final currentEndTime = state.epsBoostEndTime ?? now;
    final startTime = currentEndTime.isAfter(now) ? currentEndTime : now;

    state = state.copyWith(
      epsBoostEndTime: startTime.add(const Duration(minutes: 3)),
      lastAdEpsBoostTime: now,
    );

    SoundManager().playFanfare();
    _save();
  }

  // === Health Connect Helpers ===

  Future<HealthConnectSdkStatus?> checkHealthConnectStatus() {
    return _healthRepository.getHealthConnectSdkStatus();
  }

  Future<void> installHealthConnect() {
    return _healthRepository.installHealthConnect();
  }

  Future<bool> checkHealthPermissions() {
    return _healthRepository.hasPermissions();
  }

  Future<bool> requestHealthPermissions() async {
    final result = await _healthRepository.requestPermissions();
    if (result) {
      await syncSteps();
    }
    return result;
  }

  Future<void> openDeviceSettings() {
    return _healthRepository.openDeviceSettings();
  }

  /// EPSブーストを購入 (課金)
  /// [minutes] 分数
  /// [cost] 価格 (Gems)
  bool purchaseEpsBoost(int minutes, int cost) {
    if (state.gems < cost) return false;

    final now = DateTime.now();
    final currentEndTime = state.epsBoostEndTime ?? now;
    final startTime = currentEndTime.isAfter(now) ? currentEndTime : now;

    state = state.copyWith(
      gems: state.gems - cost,
      epsBoostEndTime: startTime.add(Duration(minutes: minutes)),
    );

    SoundManager().playFanfare(); // 購入成功音
    _save();
    return true;
  }

  // === Tap Boost (x5) Logic ===

  /// タップブーストの広告が見られるか
  bool get canWatchAdTapBoost {
    if (state.lastAdTapBoostTime == null) return true;
    final diff = DateTime.now().difference(state.lastAdTapBoostTime!);
    return diff.inMinutes >= 15;
  }

  /// タップブーストの広告再生残り時間
  Duration get adTapBoostCooldown {
    if (state.lastAdTapBoostTime == null) return Duration.zero;
    final diff = DateTime.now().difference(state.lastAdTapBoostTime!);
    final remaining = const Duration(minutes: 15) - diff;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 広告を見てタップブースト (3分間5倍 - 無料)
  Future<bool> watchAdForTapBoost() async {
    if (!canWatchAdTapBoost) return false;

    // Pro User: Instant Reward
    if (isPro) {
      await Future.delayed(const Duration(milliseconds: 500));
      _grantTapBoostReward();
      return true;
    }

    final result = await _adService.watchAd();
    if (result) {
      _grantTapBoostReward();
      return true;
    }
    return false;
  }

  void _grantTapBoostReward() {
    final now = DateTime.now();
    final currentEndTime = state.tapBoostEndTime ?? now;
    final startTime = currentEndTime.isAfter(now) ? currentEndTime : now;

    state = state.copyWith(
      tapBoostEndTime: startTime.add(const Duration(minutes: 3)),
      lastAdTapBoostTime: now,
    );
    SoundManager().playFanfare();
    _save();
  }

  /// タップブーストを購入 (課金)
  /// [minutes] 分数
  /// [cost] 価格 (Gems)
  bool purchaseTapBoost(int minutes, int cost) {
    if (state.gems < cost) return false;

    final now = DateTime.now();
    final currentEndTime = state.tapBoostEndTime ?? now;
    final startTime = currentEndTime.isAfter(now) ? currentEndTime : now;

    state = state.copyWith(
      gems: state.gems - cost,
      tapBoostEndTime: startTime.add(const Duration(minutes: 15)),
      lastAdTapBoostTime: now,
    );

    SoundManager().playFanfare(); // 購入成功音
    _save();
    return true;
  }

  /// RevenueCat Paywallを表示
  Future<void> presentPaywall() async {
    await _purchaseService.presentPaywall();
    // 閉じた後にステータス更新確認
    isPro = await _purchaseService.isProUser();
    // UI更新のために空のstate更新などが必要なら行う (今回はisProがフィールドなので簡易的に)
    // リビルドを促すためにstateを再セット
    state = state.copyWith();
  }

  /// Customer Centerを表示
  Future<void> presentCustomerCenter() async {
    await _purchaseService.presentCustomerCenter();
    // 閉じた後にステータス更新確認
    isPro = await _purchaseService.isProUser();
    state = state.copyWith();
  }

  /// ジェムを追加 (IAP後などに呼び出し)
  void addGems(int amount) {
    state = state.copyWith(gold: state.gold, gems: state.gems + amount);
    _save();
  }
}

/// ゲーム状態のプロバイダー
final gameProvider = NotifierProvider<GameNotifier, PlayerStats>(
  GameNotifier.new,
);
