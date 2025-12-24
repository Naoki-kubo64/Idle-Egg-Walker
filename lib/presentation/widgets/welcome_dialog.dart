import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:egg_walker/gen/app_localizations.dart';

class WelcomeBackDialog extends StatelessWidget {
  final int steps;
  final int stepExp;
  final int timeExp;

  const WelcomeBackDialog({
    super.key,
    required this.steps,
    required this.stepExp,
    required this.timeExp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentGold, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.welcomeBackTitle,
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // 歩数
            _buildRow(
              iconPath: 'assets/images/ui/icon_shoes.png',
              label: l10n.stepsWalked,
              value: '$steps ${l10n.steps}',
              fallbackIcon: Icons.directions_walk,
              color: AppTheme.accentPink,
            ),
            const SizedBox(height: 16),
            // 歩数EXP
            _buildRow(
              iconPath: 'assets/images/ui/icon_sword.png',
              label:
                  '${l10n.expGained} (${l10n.steps}分)', // 簡易的なラベル（本来は翻訳キーを追加すべき）
              value: '$stepExp ${l10n.exp}',
              fallbackIcon: Icons.bolt,
              color: AppTheme.accentGold,
            ),
            const SizedBox(height: 16),
            // 放置EXP
            _buildRow(
              iconPath: 'assets/images/ui/icon_sword.png',
              label: '${l10n.expGained} (放置分)', // 簡易的なラベル
              value: '$timeExp ${l10n.exp}',
              fallbackIcon: Icons.bolt,
              color: AppTheme.accentGold,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.ok,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required String iconPath,
    required String label,
    required String value,
    required IconData fallbackIcon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              iconPath,
              errorBuilder: (c, e, s) => Icon(fallbackIcon, color: color),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
