import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/sound_manager.dart'; // 追加
import 'services/notification_service.dart'; // 追加

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // サービスの初期化
  await NotificationService().init();
  await NotificationService().requestPermissions();

  await SoundManager().init();
  // SoundManager().playBgm(); // Webの自動再生ポリシーによりここでは再生せず、初回タップ時に再生する

  runApp(const ProviderScope(child: EggWalkerApp()));
}

class EggWalkerApp extends ConsumerStatefulWidget {
  const EggWalkerApp({super.key});

  @override
  ConsumerState<EggWalkerApp> createState() => _EggWalkerAppState();
}

class _EggWalkerAppState extends ConsumerState<EggWalkerApp> {
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
