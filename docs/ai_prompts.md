# 🎨 Egg Walker - AI Image Generation Guide

Nano Banana などの画像生成 AI を使用して、ゲーム用のアセットを生成するためのガイドラインです。
一貫性のあるスタイル（高品質なドット絵）を維持するためのプロンプト集です。

## 共通設定 (Base Style)

すべての生成で以下のキーワードを含めるとスタイルが統一されます。

> **Positive Prompt:** > `pixel art, 16-bit, retro game style, high quality, sprite sheet style, white background, clean edges, vibrant colors`

> **Negative Prompt:** > `blur, realistic, 3d, vector, gradient, messy, crop, text, watermark, noise`

---

## 🥚 1. 卵 (Egg)

モンスターの素となる卵。模様や色を変えてバリエーションを出します。

**Prompt:**

```
pixel art of a mysterious monster egg, oval shape, magical aura, detailed patterns, 16-bit retro style, white background
```

**バリエーションのヒント:**

- `dragon egg with scales` (ドラゴンの鱗)
- `mecha egg, robotic parts` (メカっぽい)
- `crystal egg, glowing` (クリスタル)
- `fluffy fur egg` (もふもふ)

---

## 🐉 2. モンスター (Monsters)

進化段階ごとにサイズ感と複雑さを変えます。

### 段階 1: 幼体 (Baby)

小さくてシンプル、可愛らしいデザイン。

**Prompt:**

```
pixel art of a cute baby monster, [TYPE], small body, big head, chibi style, simple design, happy expression, 16-bit, white background
```

_`[TYPE]` には `dragon`, `slime`, `robot`, `wolf` などを入れます。_

### 段階 2: 成長体 (Teen)

特徴が出てきて、少し手足がしっかりしたデザイン。

**Prompt:**

```
pixel art of a young [TYPE] monster, evolving, cool pose, standing, dynamic, expressive, 16-bit, white background
```

### 段階 3: 成体 (Adult / Final)

複雑で豪華、エフェクトを纏ったり威厳のあるデザイン。

**Prompt:**

```
pixel art of a powerful adult [TYPE] monster, fully evolved, detailed armor/scales, magical effects, epic pose, masterpiece, 16-bit, white background
```

---

## 🏞️ 3. 背景 (Backgrounds)

アプリの背景用。キャラクターを引き立てるため、少し暗めかコントラストを抑えめにすると良いです。

**Prompt:**

```
pixel art landscape, [THEME], vertical wallpaper, seamless pattern looks, retro game background, dithering, dark atmosphere
```

**テーマ例:**

- `magical forest at night` (夜の魔法の森)
- `cyberpunk city street` (サイバーパンクな街)
- `floating island in sky` (空に浮く島)

---

## 🧩 アセット制作ワークフロー

1. **生成**: 上記プロンプトで画像を大量生成する。
2. **選別**: 気に入った画像をピックアップ。
3. **背景削除**: Photoshop や Web ツールで背景を透明化する。（重要！）
4. **取り込み**: `import_assets.dart` スクリプトを使ってアプリに取り込む。
