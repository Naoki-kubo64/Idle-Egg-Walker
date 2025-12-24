import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:egg_walker/gen/app_localizations.dart';

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
  SoundManager().playBgm(); // 起動時にBGM再生を試みる

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'), // 日本語
        Locale('en'), // 英語
      ],
      home: const MainScreen(),
    );
  }
}
