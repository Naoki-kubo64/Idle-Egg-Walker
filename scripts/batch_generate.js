const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// === 設定 ===
// 生成するモンスターの定義 [ID, BasePrompt]
const MONSTERS = [
  // 既存
  { id: 3, name: 'Ghost', theme: 'cute spooky ghost spirit, purple and white' },
  { id: 4, name: 'Golem', theme: 'rock stone golem, earthy colors' },
  { id: 5, name: 'Fairy', theme: 'magical fairy with wings, nature green and pink' },
  { id: 6, name: 'Wolf', theme: 'cool wild wolf, grey and blue fur' },
  { id: 7, name: 'Robot', theme: 'retro rusty robot machine, metallic' },
  { id: 8, name: 'Plant', theme: 'carnivorous plant monster, venus flytrap style' },
  { id: 9, name: 'Bat', theme: 'flying vampire bat, dark colors' },
  { id: 10, name: 'Penguin', theme: 'cute penguin with ice crystal, blue and white' },
  { id: 11, name: 'Mimic', theme: 'monster chest mimic with tongue out, wooden texture' },
  { id: 12, name: 'UFO', theme: 'alien spaceship creature, floating, sci-fi style' },
  // 新規追加
  { id: 13, name: 'Wyvern', theme: 'flying wyvern dragon, green and yellow, wings' },
  { id: 14, name: 'Skeleton', theme: 'cute skeleton warrior, bone, pixel art' },
  { id: 15, name: 'Yeti', theme: 'snow yeti monster, white fur, big' },
  { id: 16, name: 'Cactus', theme: 'cactus monster with flower, desert' },
  { id: 17, name: 'Jellyfish', theme: 'floating jellyfish, neon blue and pink, electric' },
  { id: 18, name: 'Ninja', theme: 'shadow ninja character, black and red' },
  { id: 19, name: 'Samurai', theme: 'samurai warrior armor, japanese style' },
  { id: 20, name: 'Wizard', theme: 'magic wizard with hat and staff, blue robe' },
  { id: 21, name: 'Knight', theme: 'heavy armor knight, sword and shield, silver' },
  { id: 22, name: 'Devil', theme: 'cute little devil demon, red with horns and tail' },
];

const STAGES = [
  { suffix: 'baby', promptExtra: 'baby version, small, cute, round shape, egg shell fragments' },
  { suffix: 'teen', promptExtra: 'teen version, evolved, stronger, energetic pose' },
  { suffix: 'adult', promptExtra: 'adult version, fully evolved, powerful, majestic, final form' },
];

// ベースとなるスタイルプロンプト
const BASE_STYLE = 'pixel art style, game sprite, white background, single character, centered, high quality, retro game asset';

// 出力ディレクトリ
const OUT_DIR = path.resolve(__dirname, '../assets/images/monsters');

// === 実行関数 ===
async function run() {
  // ディレクトリ確認
  if (!fs.existsSync(OUT_DIR)) {
    console.error(`Directory not found: ${OUT_DIR}`);
    process.exit(1);
  }

  for (const monster of MONSTERS) {
    console.log(`\n=== Generating Monster ID ${monster.id}: ${monster.name} ===`);
    
    for (const stage of STAGES) {
      const filename = `monster_${monster.id.toString().padStart(3, '0')}_${stage.suffix}.png`;
      const outputPath = path.join(OUT_DIR, filename);
      
      // 画像が存在する場合はスキップ（重要）
      if (fs.existsSync(outputPath)) {
        console.log(`Skipping ${filename} (already exists)`);
        continue;
      }

      // プロンプト構築
      const prompt = `${monster.theme}, ${stage.promptExtra}, ${BASE_STYLE}`;
      
      console.log(`Generating ${stage.suffix}...`);
      
      try {
        // generate_image.mjs を実行
        const cmd = `node scripts/generate_image.mjs "${prompt}" "${outputPath}"`;
        execSync(cmd, { stdio: 'inherit', cwd: process.cwd() });
        
        // APIレート制限回避のためのウェイト
        console.log('Waiting for cooldown...');
        await new Promise(r => setTimeout(r, 5000)); 
        
      } catch (e) {
        console.error(`Failed to generate ${filename}`);
      }
    }
  }
}

run();
