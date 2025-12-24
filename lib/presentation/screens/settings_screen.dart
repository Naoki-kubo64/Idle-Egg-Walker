import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sound_manager.dart';
import 'package:egg_walker/gen/app_localizations.dart';
import 'rules_screen.dart';
import 'debug_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _soundManager = SoundManager();
  late double _bgmVolume;
  late double _seVolume;

  @override
  void initState() {
    super.initState();
    _bgmVolume = _soundManager.bgmVolume;
    _seVolume = _soundManager.seVolume;
  }

  @override
  Widget build(BuildContext context) {
    // コンテキストからローカライゼーションを取得
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(l10n.soundSettings),
              const SizedBox(height: 24),
              _buildVolumeSlider(
                label: l10n.bgmVolume,
                value: _bgmVolume,
                onChanged: (value) {
                  setState(() => _bgmVolume = value);
                  _soundManager.setBgmVolume(value);
                },
              ),
              const SizedBox(height: 32),
              _buildVolumeSlider(
                label: l10n.seVolume,
                value: _seVolume,
                onChanged: (value) {
                  setState(() => _seVolume = value);
                  _soundManager.setSeVolume(value);
                },
                onChangeEnd: (value) {
                  _soundManager.playDecide(); // 音量確認用SE
                },
              ),
              const SizedBox(height: 48),
              // 言語設定などはシステム依存だが、将来的に追加可能
              const SizedBox(height: 48),
              _buildSectionTitle('その他'),
              const SizedBox(height: 16),
              _buildSettingsButton(
                icon: Icons.menu_book_rounded,
                label: 'ゲームルール・仕様',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RulesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingsButton(
                icon: Icons.bug_report,
                label: 'Debug Logs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugLogScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                value == 0 ? Icons.volume_off : Icons.volume_down,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.textMuted,
                    thumbColor: AppTheme.secondaryColor,
                    overlayColor: AppTheme.secondaryColor.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: onChanged,
                    onChangeEnd: onChangeEnd,
                  ),
                ),
              ),
              const Icon(
                Icons.volume_up,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
