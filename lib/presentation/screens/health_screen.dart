import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/game_notifier.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gameProvider);

    // カロリー計算（簡易）
    final calories = stats.totalCaloriesBurned;
    final progress = (stats.totalSteps / stats.dailyStepGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent, // 背景はMainScreenで管理
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // タイトル
              Center(
                child: Text(
                  'HEALTH LOG',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 32),

              // メインカード（歩数計）
              _buildStepCard(stats.totalSteps, stats.dailyStepGoal, progress),

              const SizedBox(height: 24),

              // カロリーカード
              _buildCalorieCard(calories, stats.weightKg),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(int steps, int goal, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceWood, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surfaceWood.withValues(alpha: 0.4),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TODAY\'S STEPS',
            style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 16,
                  backgroundColor: AppTheme.backgroundLight,
                  color: AppTheme.secondaryColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                  Text(
                    '$steps',
                    style: AppTheme.headlineLarge.copyWith(fontSize: 40),
                  ),
                  Text('/$goal', style: AppTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildCalorieCard(double calories, double weight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceWood, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surfaceWood.withValues(alpha: 0.3),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentPink.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppTheme.accentPink,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CALORIES',
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${calories.toStringAsFixed(1)} kcal',
                style: AppTheme.headlineMedium,
              ),
            ],
          ),
        ],
      ),
    ).animate().slideX(delay: 400.ms, begin: 0.2, end: 0);
  }
}
