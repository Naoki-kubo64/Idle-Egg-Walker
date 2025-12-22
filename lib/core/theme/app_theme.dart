import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリのテーマ設定
class AppTheme {
  AppTheme._();

  // === カラーパレット（ダークテーマベース） ===
  static const Color primaryColor = Color(0xFF7C4DFF);      // 紫色（メイン）
  static const Color secondaryColor = Color(0xFF00E5FF);    // シアン（アクセント）
  static const Color accentGold = Color(0xFFFFD700);        // ゴールド（EXP）
  static const Color accentPink = Color(0xFFFF6B9D);        // ピンク（レア度）
  
  static const Color backgroundDark = Color(0xFF0D1117);    // 深い背景
  static const Color surfaceDark = Color(0xFF161B22);       // カード背景
  static const Color surfaceLight = Color(0xFF21262D);      // 軽い表面
  
  static const Color textPrimary = Color(0xFFE6EDF3);       // メインテキスト
  static const Color textSecondary = Color(0xFF8B949E);     // サブテキスト
  static const Color textMuted = Color(0xFF484F58);         // 薄いテキスト
  
  // === グラデーション ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF536DFE)],
  );
  
  static const LinearGradient expGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentGold, Color(0xFFFFAB00)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F0F23),
    ],
  );

  // === テキストスタイル（ピクセルフォント） ===
  static TextStyle get pixelFont => GoogleFonts.dotGothic16();
  
  static TextStyle get headlineLarge => GoogleFonts.dotGothic16(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 2,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.dotGothic16(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle get titleLarge => GoogleFonts.dotGothic16(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.dotGothic16(
    fontSize: 16,
    color: textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.dotGothic16(
    fontSize: 14,
    color: textSecondary,
  );
  
  static TextStyle get labelLarge => GoogleFonts.dotGothic16(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static TextStyle get expStyle => GoogleFonts.dotGothic16(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: accentGold,
    shadows: [
      Shadow(
        color: accentGold.withValues(alpha: 0.5),
        blurRadius: 8,
      ),
    ],
  );

  // === ダークテーマ ===
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceDark,
      error: Color(0xFFFF5252),
    ),
    
    textTheme: TextTheme(
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelLarge: labelLarge,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineMedium,
    ),
    
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: labelLarge,
      ),
    ),
  );

  // === レアリティカラー ===
  static Color getRarityColor(int rarity) {
    return switch (rarity) {
      1 => const Color(0xFF9E9E9E),   // ノーマル - グレー
      2 => const Color(0xFF4FC3F7),   // レア - 水色
      3 => const Color(0xFFAB47BC),   // スーパーレア - 紫
      4 => const Color(0xFFFFD54F),   // ウルトラレア - 金
      5 => const Color(0xFFFF6B9D),   // レジェンド - ピンク (虹効果推奨)
      _ => textSecondary,
    };
  }
  
  static String getRarityName(int rarity) {
    return switch (rarity) {
      1 => 'N',
      2 => 'R',
      3 => 'SR',
      4 => 'UR',
      5 => 'LG',
      _ => '?',
    };
  }
}
