import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final targetDirs = ['assets/images/egg', 'assets/images/monsters'];

  print('🎨 画像の透過処理を開始します...');

  for (final dirPath in targetDirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      print('⚠️ ディレクトリが見つかりません: $dirPath');
      continue;
    }

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.png')) {
        await processImage(entity);
      }
    }
  }

  print('✅ 全処理が完了しました！');
}

Future<void> processImage(File file) async {
  print('Processing: ${file.path}');

  try {
    final bytes = await file.readAsBytes();
    final image = decodePng(bytes);

    if (image == null) {
      print('❌ 画像のデコードに失敗しました: ${file.path}');
      return;
    }

    // 画像が既にアルファチャンネルを持っているか確認し、なければ追加
    // ライブラリの仕様上、decodePngで得られる画像は操作可能

    // 左上のピクセル色を取得
    final bgColor = image.getPixel(0, 0);
    final bgR = bgColor.r;
    final bgG = bgColor.g;
    final bgB = bgColor.b;

    // 許容誤差
    const threshold = 20; // 少し緩めに

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

        // 条件2: 純白に近い (RGBすべて240以上)
        // AI生成画像は背景が完全な白(#FFFFFF)でないことが多い
        final isWhite = r > 230 && g > 230 && b > 230;

        if (isCornerColor || isWhite) {
          // 透明にする (R=0, G=0, B=0, A=0)
          image.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    // 上書き保存
    await file.writeAsBytes(encodePng(image));
    print('✨ 透過処理完了: ${file.path}');
  } catch (e) {
    print('❌ エラー発生: $e');
  }
}
