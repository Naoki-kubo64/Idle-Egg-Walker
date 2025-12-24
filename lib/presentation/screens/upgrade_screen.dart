import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../../core/theme/app_theme.dart';
import '../../providers/game_notifier.dart';
import 'package:egg_walker/gen/app_localizations.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerStats = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final isPro = notifier.isPro;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.shop),
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
                  _buildIcon(
                    'assets/images/ui/icon_gold.png',
                    Icons.monetization_on_rounded,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${playerStats.gold} G',
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Gems
                  GestureDetector(
                    onTap: () => _showGemShopDialog(context, notifier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildIcon(
                            'assets/images/ui/icon_gem.png',
                            Icons.diamond_rounded,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${playerStats.gems}',
                            style: AppTheme.headlineMedium.copyWith(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.add_circle,
                            color: Colors.cyanAccent,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Pro Subscription Banner
            GestureDetector(
              onTap: () {
                if (kIsWeb) {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Not Supported'),
                          content: const Text(
                            'Web版では課金機能（Paywall）は利用できません。\nモバイル版をご利用ください。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                  return;
                }

                if (notifier.isPro) {
                  notifier.presentCustomerCenter();
                } else {
                  notifier.presentPaywall();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        notifier.isPro
                            ? [Colors.green.shade800, Colors.green.shade600]
                            : [Colors.purple.shade800, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (notifier.isPro ? Colors.green : Colors.purple)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notifier.isPro
                              ? 'Egg Walker Pro (Active)'
                              : 'Egg Walker Pro',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          notifier.isPro ? 'サブスクリプションを管理' : '広告なしで快適プレイ！',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      notifier.isPro
                          ? Icons.check_circle
                          : Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.upgradeHeader,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Attack Upgrade (Friend)
                  _buildUpgradeCard(
                    context: context,
                    icon: _buildIcon(
                      'assets/images/ui/icon_sword.png',
                      Icons.colorize_rounded,
                    ),
                    title: l10n.upgradeAttack,
                    description: 'おともだちの攻撃力ボーナスが増加します。\n1Lvごとに+10%',
                    currentLevel: playerStats.attackUpgradeLevel,
                    cost: notifier.attackUpgradeCost,
                    canAfford: playerStats.gold >= notifier.attackUpgradeCost,
                    onPurchase: () {
                      if (notifier.purchaseAttackUpgrade()) {
                        _showSuccessEffect(context);
                      }
                    },
                    // Ad Logic
                    canWatchAd: notifier.canWatchAdAttackUpgrade,
                    adCooldown: notifier.adAttackUpgradeCooldown,
                    onWatchAd: () async {
                      final success = await notifier.watchAdForAttackUpgrade();
                      if (success && context.mounted) {
                        _showSuccessEffect(context);
                      }
                    },
                    isPro: isPro,
                  ),
                  const SizedBox(height: 16),
                  // Tap Upgrade (Player)
                  _buildUpgradeCard(
                    context: context,
                    icon: _buildIcon(
                      'assets/images/ui/icon_tap.png',
                      Icons.touch_app_rounded,
                    ),
                    title: l10n.upgradeTap,
                    description: 'タップした時の基本経験値が増加します。\n1Lvごとに+5%',
                    currentLevel: playerStats.tapUpgradeLevel,
                    cost: notifier.tapUpgradeCost,
                    canAfford: playerStats.gold >= notifier.tapUpgradeCost,
                    onPurchase: () {
                      if (notifier.purchaseTapUpgrade()) {
                        _showSuccessEffect(context);
                      }
                    },
                    // Ad Logic for Tap Upgrade
                    canWatchAd: notifier.canWatchAdTapUpgrade,
                    adCooldown: notifier.adTapUpgradeCooldown,
                    onWatchAd: () async {
                      final success = await notifier.watchAdForTapUpgrade();
                      if (success && context.mounted) {
                        _showSuccessEffect(context);
                      }
                    },
                    isPro: isPro,
                  ),
                  const SizedBox(height: 16),
                  // Step Booster
                  _buildBoosterCard(
                    context: context,
                    icon: _buildIcon(
                      'assets/images/ui/icon_shoes.png',
                      Icons.directions_run_rounded,
                    ),
                    title: l10n.upgradeStep,
                    description: '30分間、歩いた時の経験値が2倍になります。\n重複購入で時間延長可能。',
                    boostEndTime: playerStats.stepBoostEndTime,
                    cost: notifier.stepBoostCost,
                    canAfford: playerStats.gold >= notifier.stepBoostCost,
                    onPurchase: () {
                      if (notifier.purchaseStepBoost()) {
                        _showSuccessEffect(context);
                      }
                    },
                    // Ad Logic
                    canWatchAd: notifier.canWatchAdStepBoost,
                    adCooldown: notifier.adStepBoostCooldown,
                    onWatchAd: () async {
                      final success = await notifier.watchAdForStepBoost();
                      if (success && context.mounted) {
                        _showSuccessEffect(context);
                      }
                    },
                    isPro: isPro,
                  ),
                  const SizedBox(height: 16),
                  // EPS x10 Boost
                  _buildEpsBoostCard(
                    context: context,
                    icon: _buildIcon(
                      'assets/images/ui/icon_flash.png',
                      Icons.flash_on_rounded,
                    ),
                    title: 'EPS 10倍ブースト',
                    description: '一定時間、自動経験値が10倍になります。',
                    boostEndTime: playerStats.epsBoostEndTime,
                    canAfford3m: playerStats.gems >= 10,
                    canAfford5m: playerStats.gems >= 15,
                    canAfford10m: playerStats.gems >= 25,
                    onPurchase: (minutes, cost) {
                      if (notifier.purchaseEpsBoost(minutes, cost)) {
                        _showSuccessEffect(context);
                      }
                    },
                    canWatchAd: notifier.canWatchAdEpsBoost,
                    adCooldown: notifier.adEpsBoostCooldown,
                    onWatchAd: () async {
                      final success = await notifier.watchAdForEpsBoost();
                      if (success && context.mounted) {
                        _showSuccessEffect(context);
                      }
                    },
                    isPro: isPro,
                  ),
                  const SizedBox(height: 16),
                  // Tap Power x5 Boost
                  _buildEpsBoostCard(
                    context: context,
                    icon: _buildIcon(
                      'assets/images/ui/icon_muscle.png',
                      Icons.fitness_center_rounded,
                    ),
                    title: 'タップ力 5倍ブースト',
                    description: '一定時間、タップ攻撃力が5倍になります。',
                    boostEndTime: playerStats.tapBoostEndTime,
                    canAfford3m: playerStats.gems >= 10,
                    canAfford5m: playerStats.gems >= 15,
                    canAfford10m: playerStats.gems >= 25,
                    onPurchase: (minutes, cost) {
                      if (notifier.purchaseTapBoost(minutes, cost)) {
                        _showSuccessEffect(context);
                      }
                    },
                    canWatchAd: notifier.canWatchAdTapBoost,
                    adCooldown: notifier.adTapBoostCooldown,
                    onWatchAd: () async {
                      final success = await notifier.watchAdForTapBoost();
                      if (success && context.mounted) {
                        _showSuccessEffect(context);
                      }
                    },
                    isPro: isPro,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String path, IconData fallback) {
    return Image.asset(
      path,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallback, size: 32, color: AppTheme.primaryColor);
      },
    );
  }

  Widget _buildUpgradeCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String description,
    required int currentLevel,
    required int cost,
    required bool canAfford,
    required VoidCallback onPurchase,
    // Ad params
    bool canWatchAd = false,
    Duration adCooldown = Duration.zero,
    VoidCallback? onWatchAd,
    required bool isPro,
  }) {
    String formatDuration(Duration d) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

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
            child: icon,
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
          Column(
            children: [
              ElevatedButton(
                onPressed: canAfford ? onPurchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canAfford ? AppTheme.primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
              if (onWatchAd != null) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (canWatchAd || isPro) ? onWatchAd : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canWatchAd || isPro ? AppTheme.accentGold : Colors.grey,
                    foregroundColor: AppTheme.backgroundDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (canWatchAd || isPro)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_filled, size: 16),
                            SizedBox(width: 4),
                            Text('無料UP'),
                          ],
                        )
                      else ...[
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDuration(adCooldown),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (isPro)
                        const Text(
                          '(Instant)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.greenAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showGemShopDialog(BuildContext context, GameNotifier notifier) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text(
              'Gem Shop',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ジェムを購入してブーストを有利に進めよう！\n(現在はテストモードです)',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _buildGemShopItem(
                  context,
                  notifier,
                  amount: 100,
                  price: '¥160',
                  productId: 'gem_pack_100', // Mock ID
                ),
                const SizedBox(height: 8),
                _buildGemShopItem(
                  context,
                  notifier,
                  amount: 500,
                  price: '¥800',
                  productId: 'gem_pack_500', // Mock ID
                ),
                const SizedBox(height: 8),
                // DEBUG BUTTON
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () {
                    notifier.addGems(50);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debug: Added 50 Gems')),
                    );
                  },
                  child: const Text('DEBUG: +50 Gems'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ),
    );
  }

  Widget _buildGemShopItem(
    BuildContext context,
    GameNotifier notifier, {
    required int amount,
    required String price,
    required String productId,
  }) {
    return ListTile(
      tileColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.diamond_rounded, color: Colors.cyanAccent),
      title: Text('$amount Gems', style: const TextStyle(color: Colors.white)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          // TODO: Implement RevenueCat purchase here
          // For now, simple mock
          Navigator.of(context).pop();
          // Future real implementation:
          // final customerInfo = await PurchaseService().purchasePackage(package);
          // if (customerInfo != null) notifier.addGems(amount);

          notifier.addGems(amount); // Mock success
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('購入成功: $amount Gems (Mock)')));
        },
        child: Text(price),
      ),
    );
  }

  Widget _buildEpsBoostCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String description,
    required DateTime? boostEndTime,
    required bool canAfford3m,
    required bool canAfford5m,
    required bool canAfford10m,
    required Function(int minutes, int cost) onPurchase,
    // Ad params
    bool canWatchAd = false,
    Duration adCooldown = Duration.zero,
    VoidCallback? onWatchAd,
    required bool isPro,
  }) {
    final now = DateTime.now();
    final isBoostActive = boostEndTime != null && boostEndTime.isAfter(now);
    final remainingMinutes =
        isBoostActive ? boostEndTime.difference(now).inMinutes + 1 : 0;

    String formatDuration(Duration d) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBoostActive ? AppTheme.accentGold : AppTheme.textMuted,
          width: isBoostActive ? 2 : 1,
        ),
        boxShadow:
            isBoostActive
                ? [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon,
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
                        '⚡ 残り $remainingMinutes 分',
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '未発動',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
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
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Free Ad Button
              if (onWatchAd != null)
                ElevatedButton(
                  onPressed: (canWatchAd || isPro) ? onWatchAd : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canWatchAd || isPro ? AppTheme.accentGold : Colors.grey,
                    foregroundColor: AppTheme.backgroundDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (canWatchAd || isPro)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_filled, size: 16),
                            SizedBox(width: 4),
                            Text('無料 (3分)'),
                          ],
                        )
                      else ...[
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDuration(adCooldown),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (isPro)
                        const Text(
                          'Instant',
                          style: TextStyle(fontSize: 10, color: Colors.purple),
                        ),
                    ],
                  ),
                ),
              // Paid Buttons
              _buildPaidButton(
                label: '3分',
                cost: 10,
                canAfford: canAfford3m,
                onPressed: () => onPurchase(3, 10),
              ),
              _buildPaidButton(
                label: '5分',
                cost: 15,
                canAfford: canAfford5m,
                onPressed: () => onPurchase(5, 15),
              ),
              _buildPaidButton(
                label: '10分',
                cost: 25,
                canAfford: canAfford10m,
                onPressed: () => onPurchase(10, 25),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaidButton({
    required String label,
    required int cost,
    required bool canAfford,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: canAfford ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Text(label),
          Text('$cost Gem', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBoosterCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String description,
    required DateTime? boostEndTime,
    required int cost,
    required bool canAfford,
    required VoidCallback onPurchase,
    // Ad params
    bool canWatchAd = false,
    Duration adCooldown = Duration.zero,
    VoidCallback? onWatchAd,
    required bool isPro,
  }) {
    final now = DateTime.now();
    final isBoostActive = boostEndTime != null && boostEndTime.isAfter(now);
    final remainingMinutes =
        isBoostActive ? boostEndTime.difference(now).inMinutes + 1 : 0;

    String formatDuration(Duration d) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

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
            child: icon,
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
                  Text(
                    '未発動',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
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
          Column(
            children: [
              if (!isBoostActive)
                ElevatedButton(
                  onPressed: canAfford ? onPurchase : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canAfford ? AppTheme.primaryColor : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('30分2倍'),
                      Text('$cost G', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              if (onWatchAd != null && !isBoostActive) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (canWatchAd || isPro) ? onWatchAd : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canWatchAd || isPro ? Colors.orange : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (canWatchAd || isPro)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_filled, size: 16),
                            SizedBox(width: 4),
                            Text('無料'),
                          ],
                        )
                      else ...[
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDuration(adCooldown),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (isPro)
                        const Text(
                          '(Instant)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.greenAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessEffect(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('強化に成功しました！'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
