import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'ゲームルール',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSection(
              title: '🥚 基本的な遊び方',
              content:
                  'スマートフォンを持って歩くだけ！\n'
                  '歩数に応じて卵にエネルギーがたまり、卵が割れるとモンスターが生まれます。\n'
                  'たくさん歩いて、たくさんのモンスターを集めよう！',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '🐲 進化について',
              content:
                  '同じ種類、同じ進化段階のモンスターが2体集まると、自動的に合体して次の段階へ進化します！\n\n'
                  '・Baby × 2体 ➡ Teen × 1体\n'
                  '・Teen × 2体 ➡ Adult × 1体\n\n'
                  'Adult（成体）は最強の形態です。図鑑コンプリートを目指そう！',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '📊 孵化時の確率',
              content:
                  '卵から生まれるモンスターは、以下の確率で初期の進化段階が決まります。\n\n'
                  '・Baby (幼体): 93%\n'
                  '・Teen (成長期): 5%\n'
                  '・Adult (成体): 2%\n\n'
                  '運が良ければ、いきなり成体が手に入るかも！？',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '💎 レアリティ排出率',
              content:
                  'モンスターには「レアリティ（希少度）」があります。\n'
                  '高いレアリティほど強く、出る確率は低くなります。\n\n'
                  '・Normal (N): 50%\n'
                  '・Rare (R): 30%\n'
                  '・Super Rare (SR): 15%\n'
                  '・Ultra Rare (UR): 4%\n'
                  '・Legend (LG): 1%',
            ),
            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
