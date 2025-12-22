import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/screens/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'providers/game_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EggWalkerApp()));
}

class EggWalkerApp extends ConsumerStatefulWidget {
  const EggWalkerApp({super.key});

  @override
  ConsumerState<EggWalkerApp> createState() => _EggWalkerAppState();
}

class _EggWalkerAppState extends ConsumerState<EggWalkerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // バックグラウンド復帰時に歩数同期
      _syncSteps();
    }
  }

  Future<void> _syncSteps() async {
    // GameNotifierのonAppResumeを呼び出し、獲得EXPがあれば通知
    final expGained = await ref.read(gameProvider.notifier).onAppResume();

    if (expGained > 0 && mounted) {
      // 少し遅延させてからダイアログを表示（画面描画完了待ち）
      Future.delayed(const Duration(milliseconds: 500), () {
        _showWelcomeBackDialog(expGained);
      });
    }
  }

  void _showWelcomeBackDialog(int exp) {
    // 現在のContextを取得できないため、少し強引だが
    // 実際にはNavigatorKeyを使うか、HomeScreen側で監視するのがベター
    // ここでは簡略化のため、printのみとしておくか、
    // あるいはGlobalKey<NavigatorState>を使う実装に修正する。
    // 今回はHomeScreen側でライフサイクル監視をした方が綺麗なので、
    // 本来はそちらに移すべきだが、グローバルな監視としてここに残し、
    // 通知はコンソールへ出力するのみとする（実装フェーズ2でHomeScreenへ移動）
    debugPrint('Welcome back! Gained $exp EXP');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Egg Walker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.warmTheme,
      home: const MainScreen(),
    );
  }
}
