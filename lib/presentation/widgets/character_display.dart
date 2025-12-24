import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/monster.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/gen_assets.dart';
import '../../services/sound_manager.dart';

/// キャラクター表示ウィジェット
///
/// 待機中: 呼吸するようにゆっくり伸縮
/// タップ時: ぷるんと弾むアニメーション
class CharacterDisplay extends StatefulWidget {
  final Monster? monster;
  final void Function(TapDownDetails)? onTapDown;
  final double? currentExp;
  final double? maxExp;

  const CharacterDisplay({
    super.key,
    this.monster,
    this.onTapDown,
    this.currentExp,
    this.maxExp,
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

  int _currentCrackLevel = 0;

  @override
  void initState() {
    super.initState();

    // 初期化時のひび割れレベルを計算
    _updateCrackLevel();

    // 呼吸アニメーション（常時ゆっくり）
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // バウンスアニメーション（タップ時）
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 弾性振動を見せるため少し長く
    );

    _bounceAnimation = TweenSequence<double>([
      // ギュッと縮む (素早く)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.7,
        ).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 15,
      ),
      // ビヨーンと戻る (弾性)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 85,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(CharacterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentExp != oldWidget.currentExp ||
        widget.maxExp != oldWidget.maxExp) {
      _checkCrackProgress();
    }
  }

  void _updateCrackLevel() {
    if (widget.monster?.isEgg != true) return;
    if (widget.currentExp == null ||
        widget.maxExp == null ||
        widget.maxExp == 0)
      return;
    final progress = (widget.currentExp! / widget.maxExp!).clamp(0.0, 1.0);
    // 20%刻みでレベル0〜4 (0.0, 0.2, 0.4, 0.6, 0.8)
    _currentCrackLevel = (progress * 5).floor();
  }

  void _checkCrackProgress() {
    if (widget.monster?.isEgg != true) return;
    if (widget.currentExp == null ||
        widget.maxExp == null ||
        widget.maxExp == 0)
      return;

    final progress = (widget.currentExp! / widget.maxExp!).clamp(0.0, 1.0);
    final newLevel = (progress * 5).floor();

    // レベルが上がり、かつ新しいレベルが閾値(1〜4)の場合に音を鳴らす
    // レベル0は初期状態なので鳴らさない
    if (newLevel > _currentCrackLevel && newLevel <= 4 && newLevel > 0) {
      SoundManager().playEggCrack();
    }
    _currentCrackLevel = newLevel;
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    // 連打対応: アニメーションをリセットして最初から再生
    _bounceController.forward(from: 0.0);
    widget.onTapDown?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 透明部分も反応
      onTapDown: _handleTapDown, // Downで即時反応
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathingAnimation, _bounceController]),
        builder: (context, child) {
          // 呼吸とバウンスを掛け合わせることで、いつタップしても滑らかに繋がる
          // bounceControllerの値を使ってバウンスアニメーションの値を取得
          final bounceScale = _bounceAnimation.value;
          final breathingScale = _breathingAnimation.value;

          return Transform.scale(
            scale: breathingScale * bounceScale,
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
      width: 300,
      height: 300,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        // オーラ削除
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景グロー削除

          // キャラクター画像
          _buildCharacterImage(isEgg, monster),

          // 名前タグ
          if (!isEgg && monster != null)
            Positioned(bottom: 0, child: _buildNameTag(monster)),
        ],
      ),
    );
  }

  Widget _buildCharacterImage(bool isEgg, Monster? monster) {
    String imagePath;
    if (isEgg) {
      // 卵の場合は進捗に応じて画像を変更
      double progress = 0.0;
      if (widget.currentExp != null &&
          widget.maxExp != null &&
          widget.maxExp! > 0) {
        progress = (widget.currentExp! / widget.maxExp!).clamp(0.0, 1.0);
      }
      imagePath = GenAssets.getEggImage(progress);
    } else {
      imagePath = monster?.imagePath ?? GenAssets.eggPath(1);
    }

    return Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            // color: AppTheme.surfaceDark, // 画像がある場合は背景色は不要かも
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              // 画像が見つからない場合（生成前など）はプレースホルダーを表示
              errorBuilder: (context, error, stackTrace) {
                return isEgg
                    ? _buildEggPlaceholder()
                    : _buildMonsterPlaceholder(monster!);
              },
            ),
          ),
        )
        .animate(key: ValueKey(monster?.stage)) // 進化時にフェードイン
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms);
  }

  Widget _buildEggPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🥚', style: TextStyle(fontSize: 60))
            // ... (以下略) ... 既存のアニメーションは保持したいがコードが長くなるので
            // 今回の編集範囲ではImage.assetの導入に留める
            // 省略部分は既存コードと同じ実装にする必要がありますが、
            // ReplacementContentで完全に置き換えるので、ここも再度書く必要があります。
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .rotate(
              begin: -0.02,
              end: 0.02,
              duration: 500.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 8),
        Text(
          'No Image',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMonsterPlaceholder(Monster monster) {
    // 進化段階に応じた絵文字
    final emoji = switch (monster.stage) {
      EvolutionStage.egg => '🥚',
      EvolutionStage.baby => '🐣',
      EvolutionStage.teen => '🐥',
      EvolutionStage.adult => '🐔',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 60))
            .animate(onPlay: (c) => c.repeat())
            .shake(hz: 2, offset: const Offset(2, 0), duration: 2.seconds),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.getRarityColor(
              monster.rarity,
            ).withValues(alpha: 0.2),
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
            color: AppTheme.getRarityColor(
              monster.rarity,
            ).withValues(alpha: 0.3),
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
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, duration: 300.ms);
  }
}
