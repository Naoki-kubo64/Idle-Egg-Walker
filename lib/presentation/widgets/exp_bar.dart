import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// EXPバーウィジェット
/// 
/// 現在のEXPと次の進化までの進捗を表示
class ExpBar extends StatelessWidget {
  final double currentExp;
  final double maxExp;
  
  const ExpBar({
    super.key,
    required this.currentExp,
    required this.maxExp,
  });

  double get progress => (currentExp / maxExp).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // EXP数値表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // EXPアイコン
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⚡',
                    style: TextStyle(fontSize: 14),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 2.seconds,
                  color: AppTheme.accentGold.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'EXP',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            Text(
              '${_formatNumber(currentExp)} / ${_formatNumber(maxExp)}',
              style: AppTheme.expStyle.copyWith(fontSize: 18),
            )
            .animate(
              target: currentExp > 0 ? 1 : 0,
            )
            .shimmer(
              duration: 1.seconds,
              color: AppTheme.accentGold.withValues(alpha: 0.3),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // プログレスバー
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // 背景
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                  ),
                ),
                
                // プログレス
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.expGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 2.seconds,
                    color: Colors.white.withValues(alpha: 0.3),
                    angle: 0.5,
                  ),
                ),
                
                // パーセント表示
                Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 進化までのヒント
        if (progress >= 0.8)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '✨ もうすぐ進化！',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .fade(duration: 1.seconds)
            .then()
            .fade(duration: 1.seconds, begin: 1, end: 0.5),
          ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// アニメーション付きFractionallySizedBox
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final Widget child;
  final AlignmentGeometry alignment;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    required super.duration,
    this.alignment = Alignment.centerLeft,
    super.curve = Curves.linear,
  });

  @override
  AnimatedFractionallySizedBoxState createState() => AnimatedFractionallySizedBoxState();
}

class AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}
