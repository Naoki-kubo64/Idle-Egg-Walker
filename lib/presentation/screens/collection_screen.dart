import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/gen_assets.dart';
import '../../core/constants/monster_data.dart';
import '../../providers/game_notifier.dart';
import '../../data/models/monster.dart';
import 'package:egg_walker/gen/app_localizations.dart';
import '../widgets/monster_detail_dialog.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 互換性のため discoveredIds も参照するが、基本は collectionCatalog を使う
    final catalog = ref.watch(gameProvider.select((s) => s.collectionCatalog));

    final totalMonsters = GenAssets.availableMonsterIds.length;

    // 発見数の計算（のべ種類数）
    final discoveredCount = catalog.length;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.collectionTitle),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            // 収集率ヘッダー
            _buildStatsHeader(
              context,
              discoveredCount,
              totalMonsters * 3,
            ), // 全種族x3形態
            // モンスターリスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: totalMonsters,
                itemBuilder: (context, index) {
                  final monsterId = GenAssets.availableMonsterIds[index];
                  // MonsterDataから名前を取得
                  final name = MonsterData.getName(monsterId);

                  return _CollectionRow(
                    id: monsterId,
                    name: name,
                    catalog: catalog,
                    onTap: () {
                      _showDetailDialog(context, monsterId, catalog);
                    },
                  ).animate(delay: (index * 50).ms).fadeIn().slideX();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    int monsterId,
    Map<String, int> catalog,
  ) {
    showDialog(
      context: context,
      builder:
          (context) =>
              MonsterDetailDialog(monsterId: monsterId, catalog: catalog),
    );
  }

  Widget _buildStatsHeader(BuildContext context, int discovered, int total) {
    final percentage =
        total > 0 ? (discovered / total * 100).toStringAsFixed(1) : '0.0';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.completionRate,
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentage%',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '発見形態数',
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$discovered / $total',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final int id;
  final String name;
  final Map<String, int> catalog;
  final VoidCallback onTap;

  const _CollectionRow({
    required this.id,
    required this.name,
    required this.catalog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: No.と名前 (お気に入りや詳細アイコンを追加)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'No.${id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),

            // 3形態の並び
            Row(
              children: [
                _buildStageItem(context, EvolutionStage.baby),
                const SizedBox(width: 8),
                _buildStageItem(context, EvolutionStage.teen),
                const SizedBox(width: 8),
                _buildStageItem(context, EvolutionStage.adult),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageItem(BuildContext context, EvolutionStage stage) {
    final key = '${id}_${stage.name}';
    final rarity = catalog[key]; // 未発見ならnull
    final isDiscovered = rarity != null;

    final imagePath = GenAssets.monster(id, _toMonsterStage(stage));

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.0, // 正方形
        child: Container(
          decoration: BoxDecoration(
            color:
                isDiscovered
                    ? AppTheme.getRarityColor(rarity).withValues(alpha: 0.1)
                    : Colors.black12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDiscovered
                      ? AppTheme.getRarityColor(rarity).withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // 画像
              Center(
                child:
                    isDiscovered
                        ? Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => const Text(
                                '🥚',
                                style: TextStyle(fontSize: 24),
                              ),
                        )
                        : Opacity(
                          opacity: 0.3,
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            color: Colors.black, // シルエット
                            errorBuilder:
                                (_, __, ___) => const Text(
                                  '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        ),
              ),

              // レアリティバッジ
              if (isDiscovered)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getRarityColor(rarity),
                      borderRadius: BorderRadius.circular(8),
                      // boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                    ),
                    child: Text(
                      AppTheme.getRarityName(rarity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // EvolutionStage -> MonsterStage 変換 (GenAssets用)
  MonsterStage _toMonsterStage(EvolutionStage stage) {
    return switch (stage) {
      EvolutionStage.baby => MonsterStage.baby,
      EvolutionStage.teen => MonsterStage.teen,
      EvolutionStage.adult => MonsterStage.adult,
      _ => MonsterStage.baby,
    };
  }
}
