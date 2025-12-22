import https from 'https';
import fs from 'fs';
import path from 'path';

// 環境変数または引数からAPIキーを取得
// PowerShell等で一時的に渡される場合もあるため
const API_KEY = process.env.GEMINI_API_KEY;

// モデル名
// 記事では 'gemini-3-pro-image-preview' として紹介されていたのでそのまま使用
// 状況に応じてモデル名は変更になる可能性があります
const MODEL = 'gemini-3.0-flash-exp'; // または 'imagen-3.0-generate-001' など、利用可能な画像生成モデルを指定

const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

// 引数からプロンプトと出力パスを取得
const promptArg = process.argv[2];
const outputPath = process.argv[3];

if (!promptArg || !outputPath) {
  console.error('使用方法: node scripts/generate_image.mjs "<プロンプト>" "<出力パス>"');
  console.log('例: node scripts/generate_image.mjs "pixel art of a dragon" "assets/images/monsters/dragon.png"');
  process.exit(1);
}

// ドット絵用のスタイルプロンプトを自動付与
const baseStyle = "pixel art, 16-bit, retro game style, high quality, sprite sheet style, white background, clean edges, vibrant colors";
const fullPrompt = `${baseStyle}, ${promptArg}`;

async function generateImage(prompt) {
  if (!API_KEY) {
    throw new Error('GEMINI_API_KEY が環境変数に設定されていません。');
  }

  const requestData = {
    contents: [{
      parts: [{ text: prompt }]
    }],
    generationConfig: {
      // 画像生成用パラメータ（モデルによって異なる場合あり）
      // Gemini 3系で画像生成する場合、responseMimeTypeなどを指定する場合もあるが
      // 記事の実装に従う
    }
  };

  return new Promise((resolve, reject) => {
    const requestBody = JSON.stringify(requestData);
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': API_KEY,
        'Content-Length': Buffer.byteLength(requestBody)
      }
    };

    const req = https.request(API_URL, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`JSON Parse Error: ${e.message}\nRaw Data: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(requestBody);
    req.end();
  });
}

async function main() {
  console.log(`🎨 画像生成を開始します...`);
  console.log(`Prompt: ${promptArg}`);
  console.log(`(Full: ${fullPrompt})`);

  try {
    const response = await generateImage(fullPrompt);

    // デバッグ用（レスポンス構造確認）
    // console.log(JSON.stringify(response, null, 2));

    if (response.error) {
      throw new Error(`API Error: ${response.error.message}`);
    }

    // レスポンスから画像データを抽出
    // Note: モデルによってレスポンス形式が異なる場合があります。
    // Imagen 3系やGeminiの画像生成プレビューの場合
    let base64Image = null;

    if (response.candidates?.[0]?.content?.parts) {
      for (const part of response.candidates[0].content.parts) {
        if (part.inlineData?.data) {
          base64Image = part.inlineData.data;
          break;
        }
      }
    }

    if (!base64Image) {
      console.error('❌ 画像データが見つかりませんでした。レスポンスを確認してください。');
      console.error(JSON.stringify(response, null, 2));
      process.exit(1);
    }

    const buffer = Buffer.from(base64Image, 'base64');
    
    // ディレクトリ作成
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(outputPath, buffer);
    console.log(`✅ 画像を保存しました: ${outputPath}`);

  } catch (error) {
    console.error(`❌ エラーが発生しました: ${error.message}`);
    process.exit(1);
  }
}

main();
