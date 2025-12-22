import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/monster.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/gen_assets.dart';

/// キャラクター表示ウィジェット
/// 
/// 待機中: 呼吸するようにゆっくり伸縮
/// タップ時: ぷるんと弾むアニメーション
class CharacterDisplay extends StatefulWidget {
  final Monster? monster;
  final VoidCallback? onTap;

  const CharacterDisplay({
    super.key,
    this.monster,
    this.onTap,
  });

  @override
  State<CharacterDisplay> createState() => _CharacterDisplayState();
}

class _CharacterDisplayState extends State<CharacterDisplay>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _breathingController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _breathingAnimation;
  
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    
    // 呼吸アニメーション（常時ゆっくり）
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    // バウンスアニメーション（タップ時）
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _isTapped = true);
    
    _bounceController.forward(from: 0.0).then((_) {
      setState(() => _isTapped = false);
    });
    
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathingAnimation, _bounceAnimation]),
        builder: (context, child) {
          final scale = _isTapped 
              ? _bounceAnimation.value 
              : _breathingAnimation.value;
          
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: _buildCharacterContent(),
      ),
    );
  }

  Widget _buildCharacterContent() {
    final monster = widget.monster;
    final isEgg = monster?.isEgg ?? true;
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getGlowColor().withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: _getGlowColor().withValues(alpha: 0.2),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景グロー
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getGlowColor().withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.2, 1.2),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          ),
          
          // キャラクター画像（プレースホルダー）
          _buildCharacterImage(isEgg, monster),
          
          // 名前タグ
          if (!isEgg && monster != null)
            Positioned(
              bottom: 0,
              child: _buildNameTag(monster),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterImage(bool isEgg, Monster? monster) {
    // 開発中はプレースホルダーアイコンを使用
    // 本番ではImage.assetで実際の画像を表示
    
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getGlowColor().withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Center(
        child: isEgg
            ? _buildEggPlaceholder()
            : _buildMonsterPlaceholder(monster!),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .scale(begin: const Offset(0.8, 0.8), duration: 300.ms);
  }

  Widget _buildEggPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🥚',
          style: TextStyle(fontSize: 60),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .rotate(
          begin: -0.02,
          end: 0.02,
          duration: 500.ms,
          curve: Curves.easeInOut,
        ),
        const SizedBox(height: 8),
        Text(
          'タップで温める',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMonsterPlaceholder(Monster monster) {
    // 進化段階に応じた絵文字（プレースホルダー）
    final emoji = switch (monster.stage) {
      EvolutionStage.egg => '🥚',
      EvolutionStage.baby => '🐣',
      EvolutionStage.teen => '🐥',
      EvolutionStage.adult => '🐔',
    };
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 60),
        )
        .animate(onPlay: (c) => c.repeat())
        .shake(
          hz: 2,
          offset: const Offset(2, 0),
          duration: 2.seconds,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.getRarityColor(monster.rarity).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            AppTheme.getRarityName(monster.rarity),
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 10,
              color: AppTheme.getRarityColor(monster.rarity),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameTag(Monster monster) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getRarityColor(monster.rarity).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getRarityColor(monster.rarity).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        monster.name,
        style: AppTheme.labelLarge.copyWith(
          color: AppTheme.getRarityColor(monster.rarity),
        ),
      ),
    )
    .animate()
    .fadeIn(delay: 200.ms)
    .slideY(begin: 0.3, duration: 300.ms);
  }

  Color _getGlowColor() {
    final monster = widget.monster;
    if (monster == null || monster.isEgg) {
      return AppTheme.accentGold;
    }
    return AppTheme.getRarityColor(monster.rarity);
  }
}
