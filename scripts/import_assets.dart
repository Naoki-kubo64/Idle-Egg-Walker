import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

/// アセット自動取り込みスクリプト
///
/// 使い方:
/// 1. プロジェクトルートで `dart scripts/import_assets.dart` を実行
/// 2. 入力元フォルダ（ダウンロードフォルダなど）のパスを入力
/// 3. モンスターIDと種類（baby/teen/adult）を選択
/// 4. 自動でリネームして `assets/images/` に配置されます
void main() async {
  print('🥚 Egg Walker Asset Importer 🥚');
  print('--------------------------------');

  // 1. ソースファイルの指定
  print('\n[1] 取り込む画像ファイルのフルパスを入力してください:');
  print('(例: C:\\Users\\naoki\\Downloads\\generated_image.png)');
  stdout.write('> ');
  String? sourcePath = stdin.readLineSync()?.trim().replaceAll('"', '');

  if (sourcePath == null ||
      sourcePath.isEmpty ||
      !File(sourcePath).existsSync()) {
    print('❌ エラー: ファイルが見つかりません: $sourcePath');
    return;
  }

  // 2. モンスターIDの指定
  print('\n[2] モンスターID (No.) を入力してください (1-999):');
  stdout.write('> ');
  String? idInput = stdin.readLineSync();
  int? id = int.tryParse(idInput ?? '');

  if (id == null || id < 1) {
    print('❌ エラー: 正しいIDを入力してください。');
    return;
  }

  String paddedId = id.toString().padLeft(3, '0');

  // 3. 画像タイプの選択
  print('\n[3] 画像タイプを選択してください:');
  print('1: Baby (幼体)');
  print('2: Teen (成長期)');
  print('3: Adult (成体)');
  print('4: Egg (卵)');
  stdout.write('> ');
  String? typeInput = stdin.readLineSync();

  String targetFileName;
  String targetDir;

  switch (typeInput) {
    case '1':
      targetDir = 'assets/images/monsters';
      targetFileName = 'monster_${paddedId}_baby.png';
      break;
    case '2':
      targetDir = 'assets/images/monsters';
      targetFileName = 'monster_${paddedId}_teen.png';
      break;
    case '3':
      targetDir = 'assets/images/monsters';
      targetFileName = 'monster_${paddedId}_adult.png';
      break;
    case '4':
      targetDir = 'assets/images/egg';
      targetFileName = 'egg_$paddedId.png';
      break;
    default:
      print('❌ エラー: 正しいタイプを選択してください。');
      return;
  }

  // 4. ファイル移動（コピー）
  try {
    final projectRoot = Directory.current.path;
    final destDir = Directory(p.join(projectRoot, targetDir));

    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    final destPath = p.join(destDir.path, targetFileName);

    // コピー実行
    File(sourcePath).copySync(destPath);

    print('\n✨ 成功！アセットを取り込みました:');
    print('📂 $destPath');

    // サムネイル用（図鑑用）に縮小版も作るとベストだが、
    // ここでは単純に同じ画像をサムネイル用としてもコピーしておく（仮）
    if (typeInput == '3') {
      // Adultの場合はサムネイルも作る
      final thumbDir = Directory(
        p.join(projectRoot, 'assets/images/monsters/thumbnails'),
      );
      if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

      final thumbPath = p.join(thumbDir.path, 'monster_${paddedId}_thumb.png');
      File(sourcePath).copySync(thumbPath);
      print('📂 サムネイルも作成しました: $thumbPath');
    }
  } catch (e) {
    print('❌ エラーが発生しました: $e');
  }
}
