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
import '../widgets/friend_monster.dart';

/// メインホーム画面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _backgroundController;
  final GlobalKey<ClickEffectOverlayState> _clickEffectKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundController.dispose();
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
    final expGained = await ref.read(gameProvider.notifier).onAppResume();
    if (expGained > 0 && mounted) {
      _showWelcomeBackDialog(expGained.toInt());
    }
  }

  /// おかえりダイアログ表示
  void _showWelcomeBackDialog(int expGained) {
    showDialog(
      context: context,
      builder: (context) => _WelcomeBackDialog(expGained: expGained),
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
                          // おともだち（背後のモンスターたち）
                          ...List.generate(playerStats.friends.length, (index) {
                            final friend = playerStats.friends[index];
                            final total = playerStats.friends.length;
                            final radius = 90.0; // 中心からの距離
                            // 円形配置（上側を空けて、U字型に配置するイメージ、または全周）
                            // ここではシンプルに全周配置し、少し回転させる
                            final angle =
                                (2 * math.pi * index / math.max(1, total)) -
                                (math.pi / 2);

                            return Transform.translate(
                              offset: Offset(
                                radius * math.cos(angle),
                                radius * math.sin(angle) + 20, // 少し下にずらす
                              ),
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
                icon: const Icon(Icons.menu_book_rounded),
                color: AppTheme.accentGold,
                tooltip: '図鑑',
              ),
              // 設定ボタン
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_rounded),
                color: AppTheme.textSecondary,
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
        GameConstants.expToHatch + (stats.friends.length * 500.0),
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

  /// 設定画面を開く
  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('設定画面は準備中です', style: AppTheme.bodyMedium),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
