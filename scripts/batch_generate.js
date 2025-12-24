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
  { id: 23, name: 'Phoenix', theme: 'phoenix fire bird, red and orange flame' },
  { id: 24, name: 'Unicorn', theme: 'white unicorn, horn, purity' },
  { id: 25, name: 'Griffon', theme: 'griffon, eagle head lion body, wings' },
  { id: 26, name: 'Kraken', theme: 'kraken, giant squid, octopus, ocean beast' },
  { id: 27, name: 'Mandragora', theme: 'mandragora plant monster, root anthropomorphic' },
  { id: 28, name: 'Sphinx', theme: 'sphinx, human head lion body, egyptian' },
  { id: 29, name: 'Chimera', theme: 'chimera, lion goat snake fusion beast' },
  { id: 30, name: 'Goblin', theme: 'goblin, green skin, mischievous' },
  { id: 31, name: 'Orc', theme: 'orc, warrior, tusks, green skin' },
  { id: 32, name: 'Troll', theme: 'troll, giant, club, stone skin' },
  { id: 33, name: 'Cyclops', theme: 'cyclops, one eye giant, greek mythology' },
  { id: 34, name: 'Harpy', theme: 'harpy, bird woman, wings, claws' },
  { id: 35, name: 'Mermaid', theme: 'mermaid, fish tail, underwater' },
  { id: 36, name: 'Centaur', theme: 'centaur, human torso horse body, bow' },
  { id: 37, name: 'Minotaur', theme: 'minotaur, bull head human body, axe' },
  { id: 38, name: 'Vampire', theme: 'vampire, cloak, pale skin, bats' },
  { id: 39, name: 'Werewolf', theme: 'werewolf, wolf man, full moon' },
  { id: 40, name: 'Zombie', theme: 'zombie, undead, greenish skin, spooky' },
  { id: 41, name: 'Mummy', theme: 'mummy, bandages, ancient egypt' },
  { id: 42, name: 'Gargoyle', theme: 'gargoyle, stone statue monster, wings' },
  { id: 43, name: 'Basilisk', theme: 'basilisk, snake king, deadly gaze' },
  { id: 44, name: 'Hydra', theme: 'hydra, multi headed dragon snake' },
  { id: 45, name: 'Cerberus', theme: 'cerberus, three headed dog, guardian' },
  { id: 46, name: 'Pegasus', theme: 'pegasus, winged white horse, flying' },
  { id: 47, name: 'Leviathan', theme: 'leviathan, giant sea serpent, water dragon' },
  { id: 48, name: 'Behemoth', theme: 'behemoth, giant land beast, muscular' },
  { id: 49, name: 'Mechadragon', theme: 'mecha mechanical dragon, robot, futuristic' },
  { id: 50, name: 'King Egg', theme: 'king egg, crown, royal, golden egg monster' },
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
    fs.mkdirSync(OUT_DIR, { recursive: true });
  }

  const promptListFile = path.join(__dirname, 'prompts_for_nanobanana.txt');
  let promptContent = "Filename, Prompt\n";

  console.log(`\n=== Generating Prompts for Nano Banana ===`);
  console.log(`Output: ${promptListFile}\n`);

  let count = 0;

  for (const monster of MONSTERS) {
    for (const stage of STAGES) {
      const filename = `monster_${monster.id.toString().padStart(3, '0')}_${stage.suffix}.png`;
      
      // プロンプト構築
      // Nano Banana向けに少し調整（必要であれば）
      const prompt = `${monster.theme}, ${stage.promptExtra}, ${BASE_STYLE}`;
      
      promptContent += `${filename}, "${prompt}"\n`;
      count++;
    }
  }

  fs.writeFileSync(promptListFile, promptContent);
  console.log(`Successfully generated ${count} prompts.`);
  console.log(`You can now import or paste these prompts into Nano Banana.`);
}

run();
