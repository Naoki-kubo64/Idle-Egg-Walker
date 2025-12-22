import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/game_constants.dart';
import '../../providers/game_notifier.dart';
import '../../data/models/monster.dart';
import '../widgets/character_display.dart';
import '../widgets/exp_bar.dart';
import '../widgets/stats_panel.dart';
import '../widgets/particle_effect.dart';

/// メインホーム画面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  
  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerStats = ref.watch(gameProvider);
    final currentMonster = playerStats.currentMonster;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
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
                      maxExp: _getNextEvolutionExp(currentMonster),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // キャラクター表示（タップ可能）
                  CharacterDisplay(
                    monster: currentMonster,
                    onTap: () => _onCharacterTap(),
                  ),
                  
                  const Spacer(),
                  
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
              foreground: Paint()
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
          
          // 設定ボタン
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  /// 次の進化に必要なEXPを取得
  double _getNextEvolutionExp(Monster? monster) {
    if (monster == null) return GameConstants.expToHatch;
    
    return switch (monster.stage) {
      EvolutionStage.egg => GameConstants.expToHatch,
      EvolutionStage.baby => GameConstants.expToTeen,
      EvolutionStage.teen => GameConstants.expToAdult,
      EvolutionStage.adult => GameConstants.expToAdult, // 最大値を維持
    };
  }

  /// キャラクタータップ時の処理
  void _onCharacterTap() {
    ref.read(gameProvider.notifier).onTap();
  }

  /// 設定画面を開く
  void _openSettings() {
    // TODO: 設定画面の実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '設定画面は準備中です',
          style: AppTheme.bodyMedium,
        ),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
