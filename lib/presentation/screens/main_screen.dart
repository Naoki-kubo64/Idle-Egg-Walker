import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'health_screen.dart';

/// ボトムナビゲーションを含むメイン画面
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _pages = const [HomeScreen(), HealthScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // コンテンツをバーの後ろまで伸ばす
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCream,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: AppTheme.surfaceWood, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.pets, '育成'),
          // 真ん中の区切り線
          Container(
            width: 2,
            height: 40,
            color: AppTheme.surfaceWood.withValues(alpha: 0.3),
          ),
          _buildNavItem(1, Icons.favorite, '健康'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              size: 28,
            ),
            if (isSelected)
              Text(
                label,
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
