import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/player_stats.dart';
import 'package:egg_walker/gen/app_localizations.dart';

/// 統計パネルウィジェット
///
/// タップ数、歩数、おともだち数などを表示
class StatsPanel extends StatelessWidget {
  final PlayerStats stats;

  const StatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: const Text('👆', style: TextStyle(fontSize: 24)),
            label: l10n.tapPower,
            value: _formatNumber(stats.currentTapPower),
            color: AppTheme.secondaryColor,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: const Text('⚔️', style: TextStyle(fontSize: 24)),
            label: l10n.atkPower,
            value: _formatNumber(stats.totalAttackPower.toDouble()),
            color: Colors.redAccent,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Image.asset(
              'assets/images/ui/icon_gold.png',
              width: 24,
              height: 24,
              errorBuilder:
                  (c, e, s) => const Text('💰', style: TextStyle(fontSize: 24)),
            ),
            label: l10n.gold,
            value: _formatNumber(stats.gold.toDouble()),
            color: Colors.amber,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: const Text('⚡', style: TextStyle(fontSize: 24)),
            label: l10n.eps, // Exp Per Second
            value: stats.autoExpPerSecond.toStringAsFixed(1),
            color: AppTheme.accentGold,
            isHighlighted: true,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, duration: 500.ms);
  }

  Widget _buildStatItem({
    required Widget icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: 1.seconds,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1.0, 1.0),
              duration: 1.seconds,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            shadows:
                isHighlighted
                    ? [
                      Shadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                    : null,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.textMuted.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
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
