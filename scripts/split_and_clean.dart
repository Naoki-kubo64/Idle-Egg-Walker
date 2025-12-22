import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final targetDirs = [
    'assets/images/monsters',
    // 卵は分割しない（通常1つなので）
  ];

  print('🎨 モンスター画像の透過＆切り抜き処理を開始します...');

  for (final dirPath in targetDirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.png')) {
        await processMonsterImage(entity);
      }
    }
  }

  // 卵は透過だけ行う
  final eggDir = Directory('assets/images/egg');
  if (eggDir.existsSync()) {
    await for (final entity in eggDir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.png')) {
        await makeTransparentOnly(entity);
      }
    }
  }

  print('✅ 全処理が完了しました！');
}

/// 透過処理（共通）
Image makeTransparent(Image image) {
  final bgColor = image.getPixel(0, 0);
  final bgR = bgColor.r;
  final bgG = bgColor.g;
  final bgB = bgColor.b;

  // 許容誤差
  const threshold = 30; // 厳しめに判定しない

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      // 条件1: 左上の色と近い
      final isCornerColor =
          (r - bgR).abs() < threshold &&
          (g - bgG).abs() < threshold &&
          (b - bgB).abs() < threshold;

      // 条件2: 純白に近い (RGB>230)
      final isWhite = r > 230 && g > 230 && b > 230;

      if (isCornerColor || isWhite) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return image;
}

Future<void> makeTransparentOnly(File file) async {
  print('Processing Egg: ${file.path}');
  try {
    final bytes = await file.readAsBytes();
    var image = decodePng(bytes);
    if (image == null) return;

    image = makeTransparent(image);
    await file.writeAsBytes(encodePng(image));
    print('✨ 透過完了: ${file.path}');
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> processMonsterImage(File file) async {
  print('Processing Monster: ${file.path}');
  try {
    final bytes = await file.readAsBytes();
    var image = decodePng(bytes);
    if (image == null) return;

    // まず全体を透過
    image = makeTransparent(image);

    // スプライトシート判定（3x3とみなす）
    // AI生成画像は正方形に近いことが多い
    // 中央のキャラ（index 4）だけを切り抜いて保存する

    // 3x3のグリッドサイズ計算
    final cellW = (image.width / 3).floor();
    final cellH = (image.height / 3).floor();

    // 中央のセル (x=1, y=1)
    final centerX = cellW;
    final centerY = cellH;

    // 切り抜き
    final crop = copyCrop(
      image,
      x: centerX,
      y: centerY,
      width: cellW,
      height: cellH,
    );

    // リサイズ（小さくなりすぎないようにチェック）
    // もし解像度が低ければリサイズ不要だが、画面映えのために少し大きめにリサイズしてもいいかも
    // ここではそのまま保存

    // 元ファイルに上書き保存
    await file.writeAsBytes(encodePng(crop));
    print('✂️ 切り抜き＆透過完了: ${file.path}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
