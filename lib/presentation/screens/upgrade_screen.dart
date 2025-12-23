import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/game_notifier.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('ショップ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 所持金表示
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(
                    '${state.gold} G',
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'アップグレード',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildUpgradeCard(
                    context: context,
                    icon: '⚔️',
                    title: 'おともだち攻撃力',
                    description: 'おともだちの攻撃力ボーナスが増加します。\n1Lvごとに+10%',
                    currentLevel: state.attackUpgradeLevel,
                    cost: notifier.attackUpgradeCost,
                    canAfford: state.gold >= notifier.attackUpgradeCost,
                    onPurchase: () {
                      if (notifier.purchaseAttackUpgrade()) {
                        _showSuccessEffect(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildUpgradeCard(
                    context: context,
                    icon: '👆',
                    title: 'タップ効率強化',
                    description: 'タップした時の基本経験値が増加します。\n1Lvごとに+5%',
                    currentLevel: state.tapUpgradeLevel,
                    cost: notifier.tapUpgradeCost,
                    canAfford: state.gold >= notifier.tapUpgradeCost,
                    onPurchase: () {
                      if (notifier.purchaseTapUpgrade()) {
                        _showSuccessEffect(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildBoosterCard(
                    context: context,
                    icon: '👟',
                    title: '歩数ブースト',
                    description: '30分間、歩いた時の経験値が2倍になります。\n重複購入で時間延長可能。',
                    boostEndTime: state.stepBoostEndTime,
                    cost: notifier.stepBoostCost,
                    canAfford: state.gold >= notifier.stepBoostCost,
                    onPurchase: () {
                      if (notifier.purchaseStepBoost()) {
                        _showSuccessEffect(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String description,
    required int currentLevel,
    required int cost,
    required bool canAfford,
    required VoidCallback onPurchase,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? AppTheme.primaryColor : AppTheme.textMuted,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lv.$currentLevel',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canAfford ? onPurchase : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              children: [
                const Text('強化'),
                Text('$cost G', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String description,
    required DateTime? boostEndTime,
    required int cost,
    required bool canAfford,
    required VoidCallback onPurchase,
  }) {
    final now = DateTime.now();
    final isBoostActive = boostEndTime != null && boostEndTime.isAfter(now);
    final remainingMinutes =
        isBoostActive ? boostEndTime.difference(now).inMinutes + 1 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isBoostActive
                  ? AppTheme.accentPink
                  : (canAfford ? AppTheme.primaryColor : AppTheme.textMuted),
          width: isBoostActive ? 2 : 1,
        ),
        boxShadow:
            isBoostActive
                ? [
                  BoxShadow(
                    color: AppTheme.accentPink.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isBoostActive)
                  Text(
                    '🔥 残り $remainingMinutes 分',
                    style: TextStyle(
                      color: AppTheme.accentPink,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    '未発動',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canAfford ? onPurchase : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppTheme.accentGold : Colors.grey,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Text(isBoostActive ? '延長' : '購入'),
                Text('$cost G', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessEffect(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'アップグレードしました！',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
