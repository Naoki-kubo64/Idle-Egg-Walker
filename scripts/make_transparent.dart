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

    // 左上のピクセル色を取得（これを背景色とみなす）
    final bgColor = image.getPixel(0, 0);

    // 背景色が「透明」でない場合のみ処理を実行
    if (bgColor.a != 0) {
      // 全ピクセルを走査して、背景色に近い色を透明にする
      // 許容誤差
      const threshold = 10;

      final bgR = bgColor.r;
      final bgG = bgColor.g;
      final bgB = bgColor.b;

      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);

          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;

          if ((r - bgR).abs() < threshold &&
              (g - bgG).abs() < threshold &&
              (b - bgB).abs() < threshold) {
            // 透明にする
            image.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }

      // 上書き保存
      await file.writeAsBytes(encodePng(image));
      print('✨ 透過処理完了: ${file.path}');
    } else {
      print('⏭️ 既に透過済みです: ${file.path}');
    }
  } catch (e) {
    print('❌ エラー発生: $e');
  }
}
