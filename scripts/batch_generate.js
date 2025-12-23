const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");

// === 設定 ===
// 生成するモンスターの定義 [ID, BasePrompt]
// "pixel art style", "white background" 等は generate_image.mjs 側で付与されるか、ここで付与する
// ここでは generate_image.mjs のプロンプト構築に頼らず、フルプロンプトを渡す設計にする（制御しやすいため）

const MONSTERS = [
  { id: 3, name: "Ghost", theme: "cute spooky ghost spirit, purple and white" },
  { id: 4, name: "Golem", theme: "rock stone golem, earthy colors" },
  {
    id: 5,
    name: "Fairy",
    theme: "magical fairy with wings, nature green and pink",
  },
  { id: 6, name: "Wolf", theme: "cool wild wolf, grey and blue fur" },
  { id: 7, name: "Robot", theme: "retro rusty robot machine, metallic" },
  {
    id: 8,
    name: "Plant",
    theme: "carnivorous plant monster, venus flytrap style",
  },
  { id: 9, name: "Bat", theme: "flying vampire bat, dark colors" },
  {
    id: 10,
    name: "Penguin",
    theme: "cute penguin with ice crystal, blue and white",
  },
  {
    id: 11,
    name: "Mimic",
    theme: "monster chest mimic with tongue out, wooden texture",
  },
  {
    id: 12,
    name: "UFO",
    theme: "alien spaceship creature, floating, sci-fi style",
  },
];

const STAGES = [
  {
    suffix: "baby",
    promptExtra: "baby version, small, cute, round shape, egg shell fragments",
  },
  {
    suffix: "teen",
    promptExtra: "teen version, evolved, stronger, energetic pose",
  },
  {
    suffix: "adult",
    promptExtra: "adult version, fully evolved, powerful, majestic, final form",
  },
];

// ベースとなるスタイルプロンプト
const BASE_STYLE =
  "pixel art style, game sprite, white background, single character, centered, high quality, retro game asset";

// 出力ディレクトリ
const OUT_DIR = path.resolve(__dirname, "../assets/images/monsters");

// === 実行関数 ===
async function run() {
  // ディレクトリ確認
  if (!fs.existsSync(OUT_DIR)) {
    console.error(`Directory not found: ${OUT_DIR}`);
    process.exit(1);
  }

  for (const monster of MONSTERS) {
    console.log(
      `\n=== Generating Monster ID ${monster.id}: ${monster.name} ===`
    );

    for (const stage of STAGES) {
      const filename = `monster_${monster.id.toString().padStart(3, "0")}_${
        stage.suffix
      }.png`;
      const outputPath = path.join(OUT_DIR, filename);

      // ファイルが既に存在する場合はスキップしない（上書きモード）
      // もしスキップしたい場合はここコメントアウトを外す
      // if (fs.existsSync(outputPath)) {
      //   console.log(`Skipping ${filename} (already exists)`);
      //   continue;
      // }

      // プロンプト構築
      const prompt = `${monster.theme}, ${stage.promptExtra}, ${BASE_STYLE}`;

      console.log(`Generating ${stage.suffix}...`);

      try {
        // generate_image.mjs を実行
        // node scripts/generate_image.mjs "prompt" "path"
        const cmd = `node scripts/generate_image.mjs "${prompt}" "${outputPath}"`;
        execSync(cmd, { stdio: "inherit", cwd: process.cwd() });

        // APIレート制限回避のためのウェイト (数秒)
        console.log("Waiting for cooldown...");
        await new Promise((r) => setTimeout(r, 5000));
      } catch (e) {
        console.error(`Failed to generate ${filename}`);
        // エラーでも止まらず次へ
      }
    }
  }
}

run();
