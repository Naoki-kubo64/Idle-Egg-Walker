import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/game_notifier.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('ヘルスケア設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日の成果カード
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        '総歩数',
                        '${state.totalSteps}',
                        '歩',
                        AppTheme.primaryColor,
                      ),
                      _buildStat(
                        '消費カロリー',
                        state.totalCaloriesBurned.toStringAsFixed(1),
                        'kcal',
                        AppTheme.accentGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 目標達成度バー
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '目標達成度',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            '${(state.totalSteps / state.dailyStepGoal * 100).clamp(0, 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (state.totalSteps / state.dailyStepGoal).clamp(
                            0.0,
                            1.0,
                          ),
                          minHeight: 16,
                          backgroundColor: AppTheme.backgroundLight,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'プロフィール設定',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '正確なカロリー計算のために使用されます。\nこれらの情報はアプリ内のみに保存されます。',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // 目標歩数設定
            _buildSliderParams(
              context,
              label: '1日の目標歩数',
              value: state.dailyStepGoal.toDouble(),
              min: 1000,
              max: 30000,
              divisions: 290, // 100刻み
              unit: '歩',
              icon: Icons.flag_rounded,
              onChanged: (val) {
                notifier.updateBodyProfile(dailyGoal: val.toInt());
              },
            ),

            const SizedBox(height: 16),

            // 身長設定
            _buildSliderParams(
              context,
              label: '身長',
              value: state.heightCm,
              min: 100,
              max: 250,
              divisions: 150,
              unit: 'cm',
              icon: Icons.height_rounded,
              onChanged: (val) {
                notifier.updateBodyProfile(height: val);
              },
            ),

            const SizedBox(height: 16),

            // 体重設定
            _buildSliderParams(
              context,
              label: '体重',
              value: state.weightKg,
              min: 20,
              max: 200,
              divisions: 180,
              unit: 'kg',
              icon: Icons.monitor_weight_rounded,
              onChanged: (val) {
                notifier.updateBodyProfile(weight: val);
              },
            ),

            const SizedBox(height: 16),

            // 年齢設定
            _buildSliderParams(
              context,
              label: '年齢',
              value: state.age.toDouble(),
              min: 5,
              max: 100,
              divisions: 95,
              unit: '歳',
              icon: Icons.cake_rounded,
              onChanged: (val) {
                notifier.updateBodyProfile(age: val.toInt());
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: AppTheme.headlineMedium.copyWith(color: color)),
        Text(
          unit,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSliderParams(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(0)} $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.3),
              thumbColor: AppTheme.secondaryColor,
              overlayColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
