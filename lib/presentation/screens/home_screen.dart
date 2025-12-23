import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/game_constants.dart';
import '../../providers/game_notifier.dart';
import '../../data/models/monster.dart';
import '../../data/models/player_stats.dart';
import '../widgets/character_display.dart';
import '../widgets/exp_bar.dart';
import '../widgets/stats_panel.dart';
import '../widgets/particle_effect.dart';
import '../widgets/click_effect_overlay.dart';
import 'dart:math' as math;
import 'collection_screen.dart';
import 'upgrade_screen.dart';
import 'health_screen.dart';
import '../widgets/friend_monster.dart';
import '../widgets/welcome_dialog.dart'; // 追加

/// メインホーム画面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _backgroundController;
  late AnimationController _pokeController;
  late Animation<double> _pokeAnimation;
  final GlobalKey<ClickEffectOverlayState> _clickEffectKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // つつくアニメーション: 1秒周期
    _pokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // 0.0 -> 1.0 (突く) -> 0.0 (戻る) -> 待機
    _pokeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15, // 0.15秒で突く
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15, // 0.15秒で戻る
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 70, // 残り0.7秒は待機
      ),
    ]).animate(_pokeController);

    _pokeController.repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundController.dispose();
    _pokeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBackgroundProgress();
    }
  }

  /// バックグラウンド復帰時の処理
  Future<void> _checkBackgroundProgress() async {
    // 詳細（歩数とEXP）を取得
    final result = await ref.read(gameProvider.notifier).syncAndGetDetails();
    final steps = (result['steps'] as num).toInt();
    final exp = (result['exp'] as num).toInt();

    if ((steps > 0 || exp > 0) && mounted) {
      _showWelcomeBackDialog(steps, exp);
    }
  }

  /// おかえりダイアログ表示
  void _showWelcomeBackDialog(int steps, int exp) {
    showDialog(
      context: context,
      builder: (context) => WelcomeBackDialog(steps: steps, exp: exp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerStats = ref.watch(gameProvider);
    final currentMonster = playerStats.currentMonster;

    return Scaffold(
      backgroundColor: Colors.transparent, // 背景画像を透過させる
      body: ClickEffectOverlay(
        key: _clickEffectKey,
        enableTouch: false, // キャラクタータップのみに反応させたい場合はfalse
        child: Container(
          // 背景はMainScreenで設定するため、ここは透明
          child: SafeArea(
            child: Stack(
              children: [
                // 背景パーティクル
                const ParticleEffect(),

                // メインコンテンツ
                Column(
                  children: [
                    // ヘッダー
                    _buildHeader(playerStats),

                    const SizedBox(height: 16),

                    // EXPバー
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ExpBar(
                        currentExp: playerStats.currentExp,
                        maxExp: _getNextEvolutionExp(
                          currentMonster,
                          playerStats,
                        ),
                      ),
                    ),

                    // キャラクタと友達表示エリア
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          ...List.generate(playerStats.friends.length, (index) {
                            final friend = playerStats.friends[index];

                            // 配置レイヤー（リング）の計算
                            const int maxPerRing = 15;
                            final int ringIndex = index ~/ maxPerRing;
                            final int indexInRing = index % maxPerRing;

                            // このリングに配置される総数を計算
                            int countOnLayer = maxPerRing;
                            final int remaining =
                                playerStats.friends.length -
                                (ringIndex * maxPerRing);
                            if (remaining < maxPerRing) {
                              countOnLayer = remaining;
                            }

                            // 角度: リング内の数で等分
                            final angle =
                                (2 *
                                    math.pi *
                                    indexInRing /
                                    math.max(1, countOnLayer)) -
                                (math.pi / 2);

                            return AnimatedBuilder(
                              animation: _pokeAnimation,
                              builder: (context, child) {
                                // つつきオフセット: アニメーション値(0~1) * 25px 分だけ中心に寄る
                                final pokeOffset = _pokeAnimation.value * 25.0;

                                // X軸（横）: 初期100 - poke
                                final radiusX =
                                    (100.0 + (ringIndex * 34.0)) - pokeOffset;
                                // Y軸（縦）: 初期120 - poke
                                final radiusY =
                                    (120.0 + (ringIndex * 42.0)) - pokeOffset;

                                return Transform.translate(
                                  offset: Offset(
                                    radiusX * math.cos(angle),
                                    radiusY * math.sin(angle) + 20,
                                  ),
                                  child: child,
                                );
                              },
                              child: FriendMonster(
                                monster: friend,
                                onTap: () {
                                  // おともだちをタップした時の反応（必要なら）
                                },
                              ),
                            );
                          }),

                          // メインキャラクター（卵など）
                          CharacterDisplay(
                            monster: currentMonster,
                            onTapDown: (details) {
                              _onCharacterTap(details.globalPosition);
                            },
                          ),
                        ],
                      ),
                    ),

                    // 統計パネル
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StatsPanel(stats: playerStats),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(playerStats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // タイトル
          Text(
                'Egg Walker',
                style: AppTheme.headlineMedium.copyWith(
                  foreground:
                      Paint()
                        ..shader = AppTheme.primaryGradient.createShader(
                          const Rect.fromLTWH(0, 0, 200, 40),
                        ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 3.seconds,
                color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              ),

          // 右側アクションボタン
          Row(
            children: [
              // 図鑑ボタン
              IconButton(
                onPressed: _openCollection,
                icon: Image.asset(
                  'assets/images/ui/icon_book.png',
                  width: 28,
                  height: 28,
                  errorBuilder:
                      (c, e, s) => const Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.accentGold,
                      ),
                ),
                tooltip: '図鑑',
              ),
              // ヘルスケアボタン
              IconButton(
                onPressed: _openHealth,
                icon: Image.asset(
                  'assets/images/ui/icon_health.png',
                  width: 28,
                  height: 28,
                  errorBuilder:
                      (c, e, s) => const Icon(
                        Icons.monitor_heart_outlined,
                        color: AppTheme.primaryColor,
                      ),
                ),
                tooltip: '健康設定',
              ),
              // ショップボタン
              IconButton(
                onPressed: _openShop,
                icon: Image.asset(
                  'assets/images/ui/icon_shop.png',
                  width: 28,
                  height: 28,
                  errorBuilder:
                      (c, e, s) => const Icon(
                        Icons.store_rounded,
                        color: AppTheme.accentPink,
                      ),
                ),
                tooltip: 'ショップ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 次の進化に必要なEXPを取得
  double _getNextEvolutionExp(Monster? monster, PlayerStats stats) {
    if (monster == null) return GameConstants.expToHatch;

    return switch (monster.stage) {
      EvolutionStage.egg =>
        GameConstants.expToHatch +
            (stats.friends.length * 500.0) +
            (stats.friends.length * stats.friends.length * 20.0),
      EvolutionStage.baby => GameConstants.expToTeen,
      EvolutionStage.teen => GameConstants.expToAdult,
      EvolutionStage.adult => GameConstants.expToAdult, // 最大値を維持
    };
  }

  /// キャラクタータップ時の処理
  void _onCharacterTap(Offset globalPosition) {
    ref.read(gameProvider.notifier).onTap();
    // クリックエフェクトを表示
    _clickEffectKey.currentState?.addEffect(
      globalPosition,
      exp: GameConstants.expPerTap.toInt(),
    );
  }

  /// 図鑑画面を開く
  void _openCollection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CollectionScreen()),
    );
  }

  /// ショップ画面を開く
  void _openShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpgradeScreen()),
    );
  }

  /// ヘルスケア画面を開く
  void _openHealth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthScreen()),
    );
  }
}

/// おかえりダイアログ
class _WelcomeBackDialog extends StatelessWidget {
  final int expGained;

  const _WelcomeBackDialog({required this.expGained});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child:
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'おかえりなさい！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '留守のあいだに...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: expGained),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Text(
                          '+$value EXP',
                          style: AppTheme.expStyle.copyWith(fontSize: 32),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'を獲得しました！',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              )
              .animate()
              .scale(duration: 300.ms, curve: Curves.easeOutBack)
              .fadeIn(),
    );
  }
}
