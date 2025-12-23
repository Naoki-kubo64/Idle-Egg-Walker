/// Nano Bananaで生成したアセット画像を管理するクラス
///
/// 連番管理（monster_001.png, monster_002.png...）を前提とした定数管理
class GenAssets {
  GenAssets._();

  // ベースパス
  static const String _basePath = 'assets/images';

  // === 卵アセット ===
  /// 卵画像のパスを取得
  static String eggPath(int id) {
    // 卵IDは現状連動していないが、将来的に拡張可能にする
    // 基本は 'egg_001.png' を返す
    final paddedId = id.toString().padLeft(3, '0');
    // 実ファイル運用に合わせてID:0の場合はデフォルト扱いにするなどのロジック
    if (id == 0) return '$_basePath/egg/egg_001.png';
    return '$_basePath/egg/egg_$paddedId.png';
  }

  static const String egg = '$_basePath/egg/egg_001.png'; // 互換性のため残す
  static const String eggCracking = '$_basePath/egg/egg_cracking.png';
  static const String eggHatching = '$_basePath/egg/egg_hatching.png';

  // === モンスターアセット ===
  /// モンスター画像のパスを取得（連番形式）
  /// [id] - モンスターID（1から始まる）
  /// [stage] - 進化段階（baby, teen, adult）
  static String monster(int id, MonsterStage stage) {
    final paddedId = id.toString().padLeft(3, '0');
    return '$_basePath/monsters/monster_${paddedId}_${stage.name}.png';
  }

  /// モンスターのサムネイル画像（図鑑用）
  static String monsterThumbnail(int id) {
    final paddedId = id.toString().padLeft(3, '0');
    return '$_basePath/monsters/thumbnails/monster_${paddedId}_thumb.png';
  }

  // === 背景アセット ===
  static const String backgroundDefault =
      '$_basePath/backgrounds/bg_default.png';
  static const String backgroundNight = '$_basePath/backgrounds/bg_night.png';
  static const String backgroundMorning =
      '$_basePath/backgrounds/bg_morning.png';

  // === エフェクトアセット ===
  static const String effectSparkle = '$_basePath/effects/sparkle.png';
  static const String effectHeart = '$_basePath/effects/heart.png';
  static const String effectStar = '$_basePath/effects/star.png';

  // === UIアセット ===
  static const String buttonTap = '$_basePath/ui/button_tap.png';
  static const String iconExp = '$_basePath/ui/icon_exp.png';
  static const String iconSteps = '$_basePath/ui/icon_steps.png';

  // === プレースホルダー（開発用） ===
  static const String placeholder = '$_basePath/placeholder.png';

  /// 全モンスターIDのリスト（現在登録されているもの）
  static final List<int> availableMonsterIds = List.generate(50, (i) => i + 1);

  /// 利用可能なモンスター数
  static int get totalMonsters => availableMonsterIds.length;
}

/// モンスターの進化段階
enum MonsterStage {
  baby, // 幼体
  teen, // 成長中
  adult, // 成体
}
