import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WelcomeBackDialog extends StatelessWidget {
  final int steps;
  final int exp;

  const WelcomeBackDialog({super.key, required this.steps, required this.exp});

  @override
  Widget build(BuildContext context) {
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
              'おかえりなさい！',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // 歩数
            _buildRow(
              iconPath: 'assets/images/ui/icon_shoes.png',
              label: '歩いた歩数',
              value: '$steps 歩',
              fallbackIcon: Icons.directions_walk,
              color: AppTheme.accentPink,
            ),
            const SizedBox(height: 16),
            // EXP
            _buildRow(
              iconPath: 'assets/images/ui/icon_sword.png', // 剣アイコンを代用、あるいはGold
              label: '獲得経験値',
              value: '$exp EXP',
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
                  foregroundColor:
                      AppTheme.textPrimary, // textDark -> textPrimary
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                style: AppTheme.headlineMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
