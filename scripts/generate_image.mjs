import https from 'https';
import fs from 'fs';
import path from 'path';

// ==========================================
// 設定エリア
// ==========================================

// 1. APIキー (ユーザー提供の有効なキーを直接設定)
// .env読み込みトラブルを避けるため、優先的に使用します
const HARDCODED_KEY = 'AIzaSyAE4q6PtV32-AM8lcLz5j3BtWMHhSrZJSw';

// 2. モデル名
// 利用可能なモデル: 'imagen-4.0-generate-preview-06-06' (推奨), 'imagen-3.0-generate-001'
const MODEL = 'imagen-4.0-generate-preview-06-06';

// 3. API URL
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:predict`;

// ==========================================

// 引数チェック
const promptArg = process.argv[2];
const outputPath = process.argv[3];

if (!promptArg || !outputPath) {
  console.error('使用方法: node scripts/generate_image.mjs "<プロンプト>" "<出力パス>"');
  process.exit(1);
}

// キーの決定（ハードコード優先）
let API_KEY = HARDCODED_KEY;

// .envからの読み込み（ハードコードがない場合のバックアップ）
if (!API_KEY) {
  const envPath = path.resolve(process.cwd(), '.env');
  console.log(`Checking .env at: ${envPath}`);
  if (fs.existsSync(envPath)) {
    const envConfig = fs.readFileSync(envPath, 'utf-8');
    // BOM除去とパース
    const content = envConfig.replace(/^\uFEFF/, '');
    const lines = content.split(/\r?\n/);
    for (const line of lines) {
      const match = line.match(/^\s*GEMINI_API_KEY\s*=\s*(.+?)\s*$/);
      if (match) {
        API_KEY = match[1].replace(/["']/g, '').trim();
        break;
      }
    }
  }
}

// 最終確認
if (!API_KEY) {
  console.error('❌ API Keyが見つかりません。');
  process.exit(1);
}

// デバッグ: キー情報の出力（セキュリティのため一部伏せ字）
const maskedKey = API_KEY.substring(0, 5) + '...' + API_KEY.substring(API_KEY.length - 5);
console.log(`Using API Key: ${maskedKey} (Length: ${API_KEY.length})`);

// ドット絵用のスタイルプロンプト
const baseStyle = "pixel art, 16-bit, retro game style, high quality, sprite sheet style, white background, clean edges, vibrant colors";
const fullPrompt = `${baseStyle}, ${promptArg}`;

async function generateImage(prompt) {
  // クエリパラメータでキーを渡す
  const urlWithKey = `${API_URL}?key=${API_KEY}`;

  // Imagenモデル用のリクエストボディ
  const requestData = {
    instances: [
      { prompt: prompt }
    ],
    parameters: {
      sampleCount: 1,
      aspectRatio: "16:9",
      outputOptions: { mimeType: "image/png" } 
    }
  };

  return new Promise((resolve, reject) => {
    const requestBody = JSON.stringify(requestData);
    
    // URLパース
    const urlObj = new URL(urlWithKey);

    const options = {
      method: 'POST',
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (res.statusCode !== 200) {
            reject(new Error(`API Error (${res.statusCode}): ${JSON.stringify(json, null, 2)}`));
          } else {
            resolve(json);
          }
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
  console.log(`Model: ${MODEL}`);
  console.log(`Prompt: ${promptArg}`);

  try {
    const response = await generateImage(fullPrompt);

    let base64Image = null;

    if (response.predictions && response.predictions.length > 0) {
        const prediction = response.predictions[0];
        if (prediction.bytesBase64Encoded) {
            base64Image = prediction.bytesBase64Encoded;
        } else if (prediction.mimeType && prediction.bytesBase64Encoded) {
            base64Image = prediction.bytesBase64Encoded;
        }
    }

    if (!base64Image) {
      console.error('❌ 画像データが見つかりませんでした。詳細:', JSON.stringify(response, null, 2));
      process.exit(1);
    }

    const buffer = Buffer.from(base64Image, 'base64');
    
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
