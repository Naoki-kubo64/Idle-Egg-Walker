import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/gen_assets.dart';
import '../../providers/game_notifier.dart';

/// 図鑑画面
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveredIds = ref.watch(gameProvider.select((s) => s.discoveredMonsterIds));
    final totalMonsters = GenAssets.totalMonsters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスター図鑑'),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // 収集率ヘッダー
            _buildStatsHeader(discoveredIds.length, totalMonsters),
            
            // モンスターグリッド
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: totalMonsters,
                itemBuilder: (context, index) {
                  final monsterId = index + 1; // IDは1始まり
                  final isDiscovered = discoveredIds.contains(monsterId);
                  
                  return _CollectionItem(
                    id: monsterId,
                    isDiscovered: isDiscovered,
                  )
                  .animate(delay: (index * 50).ms)
                  .fadeIn()
                  .scale();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int discovered, int total) {
    final percentage = (discovered / total * 100).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '発見率',
                style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentage%',
                style: AppTheme.headlineMedium.copyWith(color: AppTheme.secondaryColor),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: AppTheme.textMuted),
          Column(
            children: [
              Text(
                '見つけた数',
                style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '$discovered / $total',
                style: AppTheme.headlineMedium.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 個別の図鑑アイテム
class _CollectionItem extends StatelessWidget {
  final int id;
  final bool isDiscovered;

  const _CollectionItem({
    required this.id,
    required this.isDiscovered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDiscovered 
              ? AppTheme.accentGold.withValues(alpha: 0.5) 
              : AppTheme.textMuted.withValues(alpha: 0.2),
          width: isDiscovered ? 2 : 1,
        ),
        boxShadow: isDiscovered
            ? [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // モンスター画像（または「？」）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: isDiscovered
                  ? _buildMonsterImage()
                  : _buildSilhouette(),
            ),
          ),
          
          // ID表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Text(
              'No.${id.toString().padLeft(3, '0')}',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 10,
                color: isDiscovered ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterImage() {
    // 実際のアセット画像を表示（プレースホルダー）
    // GenAssets.monsterThumbnail(id) を使用する想定
    return Image.asset(
      GenAssets.monster(id, MonsterStage.adult), // 代表画像として大人の姿を使用
      errorBuilder: (context, error, stackTrace) {
        // 画像がない場合のフォールバック（開発用）
        return const Center(child: Text('🦕', style: TextStyle(fontSize: 32)));
      },
      fit: BoxFit.contain,
    );
  }

  Widget _buildSilhouette() {
    // 未発見時はシルエット（黒塗り）または「？」マーク
    return Center(
      child: Text(
        '?',
        style: AppTheme.headlineMedium.copyWith(
          color: AppTheme.textMuted.withValues(alpha: 0.5),
          fontSize: 40,
        ),
      ),
    );
  }
}
