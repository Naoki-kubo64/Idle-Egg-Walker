import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/gen_assets.dart';
import '../../core/constants/monster_data.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/monster.dart';

class MonsterDetailDialog extends StatefulWidget {
  final int monsterId;
  final Map<String, int> catalog;

  const MonsterDetailDialog({
    super.key,
    required this.monsterId,
    required this.catalog,
  });

  @override
  State<MonsterDetailDialog> createState() => _MonsterDetailDialogState();
}

class _MonsterDetailDialogState extends State<MonsterDetailDialog> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    // デフォルトで表示するページを決定（大人がいれば大人、いなければ発見済みの最高ランク）
    _currentPage = _determineInitialPage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  int _determineInitialPage() {
    if (_isDiscovered(EvolutionStage.adult)) return 2;
    if (_isDiscovered(EvolutionStage.teen)) return 1;
    return 0; // baby or default
  }

  bool _isDiscovered(EvolutionStage stage) {
    return widget.catalog['${widget.monsterId}_${stage.name}'] != null;
  }

  int? _getRarity(EvolutionStage stage) {
    return widget.catalog['${widget.monsterId}_${stage.name}'];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = MonsterData.getName(widget.monsterId);
    final description = MonsterData.getDescription(widget.monsterId);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'No.${widget.monsterId.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Image Carousel
            SizedBox(
              height: 300,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildImagePage(EvolutionStage.baby),
                  _buildImagePage(EvolutionStage.teen),
                  _buildImagePage(EvolutionStage.adult),
                ],
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(0, 'Baby'),
                const SizedBox(width: 8),
                _buildIndicator(1, 'Teen'),
                const SizedBox(width: 8),
                _buildIndicator(2, 'Adult'),
              ],
            ),

            const SizedBox(height: 16),

            // Info Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_currentPage),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isDiscovered(_getCurrentStage())) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getRarityColor(
                                      _getRarity(_getCurrentStage()) ?? 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppTheme.getRarityName(
                                      _getRarity(_getCurrentStage()) ?? 1,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '発見済み',
                                  style: TextStyle(
                                    color: AppTheme.accentGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ] else
                            const Text(
                              '未発見',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                          Text(
                            _isDiscovered(_getCurrentStage())
                                ? description
                                : '？？？',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  EvolutionStage _getCurrentStage() {
    switch (_currentPage) {
      case 0:
        return EvolutionStage.baby;
      case 1:
        return EvolutionStage.teen;
      case 2:
        return EvolutionStage.adult;
      default:
        return EvolutionStage.baby;
    }
  }

  Widget _buildImagePage(EvolutionStage stage) {
    final isDiscovered = _isDiscovered(stage);
    final imagePath = GenAssets.monster(
      widget.monsterId,
      _toMonsterStage(stage),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color:
              isDiscovered
                  ? AppTheme.backgroundLight.withValues(alpha: 0.1)
                  : Colors.black26,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDiscovered
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child:
              isDiscovered
                  ? Image.asset(imagePath, fit: BoxFit.contain)
                  : Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      color: Colors.black,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index, String label) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  MonsterStage _toMonsterStage(EvolutionStage stage) {
    return switch (stage) {
      EvolutionStage.baby => MonsterStage.baby,
      EvolutionStage.teen => MonsterStage.teen,
      EvolutionStage.adult => MonsterStage.adult,
      _ => MonsterStage.baby,
    };
  }
}
