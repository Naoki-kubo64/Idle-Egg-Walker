import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリのテーマ設定
class AppTheme {
  AppTheme._();

  // === カラーパレット（Warm Pixel Theme） ===
  static const Color primaryColor = Color(0xFF88C946); // 若草色（メイン）
  static const Color secondaryColor = Color(0xFFFFD166); // タンポポ色（アクセント）
  static const Color accentGold = Color(0xFFFFB627); // 蜂蜜色（EXP）
  static const Color accentPink = Color(0xFFFF8B94); // 桃色（ハートなど）

  static const Color backgroundLight = Color(0xFFF0F7E6); // 非常に薄い緑（昼）
  static const Color surfaceCream = Color(0xFFFFFDF5); // クリーム色（カード）
  static const Color surfaceWood = Color(0xFFD4A373); // 木目調（濃いUI）

  static const Color textPrimary = Color(0xFF4A4036); // こげ茶（メインテキスト）
  static const Color textSecondary = Color(0xFF8C7B6B); // 薄茶（サブテキスト）
  static const Color textMuted = Color(0xFFB5A698); // グレーベージュ

  // === 互換性定義（旧カラー名へのエイリアス） ===
  static const Color backgroundDark = backgroundLight;
  static const Color surfaceDark = surfaceCream;
  static const Color surfaceLight = surfaceWood;

  // === グラデーション ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA6E060), Color(0xFF7CB342)],
  );

  static const LinearGradient expGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFFCA28)],
  );

  // 空と大地のグラデーション
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF87CEEB), // 空色
      Color(0xFFE0F7FA), // 薄い雲
      Color(0xFFF1F8E9), // 地平線付近
      Color(0xFFDCEDC8), // 草原
    ],
    stops: [0.0, 0.4, 0.6, 1.0],
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

  static TextStyle get bodyLarge =>
      GoogleFonts.dotGothic16(fontSize: 16, color: textPrimary);

  static TextStyle get bodyMedium =>
      GoogleFonts.dotGothic16(fontSize: 14, color: textSecondary);

  static TextStyle get labelLarge => GoogleFonts.dotGothic16(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get expStyle => GoogleFonts.dotGothic16(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: accentGold,
    shadows: [Shadow(color: accentGold.withValues(alpha: 0.5), blurRadius: 8)],
  );

  // === ダークテーマ ===
  // === メインテーマ ===
  static ThemeData get warmTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    fontFamily: GoogleFonts.dotGothic16().fontFamily,

    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceCream,
      onPrimary: Colors.white,
      onSecondary: textPrimary,
      onSurface: textPrimary,
    ),

    // カードデザイン（ドット絵風の枠線）
    cardTheme: CardThemeData(
      color: surfaceCream,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFD7CCC8), width: 3),
      ),
    ),

    // ボタンデザイン（立体的）
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: Color(0xFF558B2F),
            width: 0,
            style: BorderStyle.none,
          ),
        ),
        textStyle: labelLarge,
      ).copyWith(
        shadowColor: WidgetStateProperty.all(const Color(0xFF558B2F)),
        elevation: WidgetStateProperty.all(4),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineMedium,
      iconTheme: const IconThemeData(color: textPrimary),
    ),
  );

  static ThemeData get darkTheme => warmTheme; // 互換性のため

  // === レアリティカラー ===
  static Color getRarityColor(int rarity) {
    return switch (rarity) {
      1 => const Color(0xFF9E9E9E), // ノーマル - グレー
      2 => const Color(0xFF4FC3F7), // レア - 水色
      3 => const Color(0xFFAB47BC), // スーパーレア - 紫
      4 => const Color(0xFFFFD54F), // ウルトラレア - 金
      5 => const Color(0xFFFF6B9D), // レジェンド - ピンク (虹効果推奨)
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
