# Ghostty GLSL Shaders

このディレクトリには、Ghosttyターミナルで使用できる31個のGLSLシェーダーファイルが含まれています。各シェーダーは、ターミナルに美しい視覚効果を追加し、より魅力的なターミナル体験を提供します。

## 使用方法

シェーダーを使用するには、Ghosttyの設定ファイル（`~/.config/ghostty/config`）に以下の行を追加します：

```
custom-shader = shaders/[シェーダーファイル名]
```

例：
```
custom-shader = shaders/cursor_blaze.glsl
```

## 利用可能なシェーダー

### CRT・レトロ効果

**bettercrt.glsl**
- CRTモニターの曲率とスキャンラインを再現
- レトロなブラウン管テレビの質感を表現

**crt.glsl**
- Timothy Lottesによる高品質CRT風シェーダー（パブリックドメイン）
- 詳細なCRT効果とフォスファーマスク

**retro-terminal.glsl**
- 緑色のレトロ端末風効果
- 古いコンピューターターミナルの雰囲気

**tft.glsl**
- TFT液晶ディスプレイ風効果
- 現代的な液晶の質感

**in-game-crt.glsl**
- ゲーム内のCRT効果
- ゲーム風のブラウン管エフェクト

### 視覚的歪み・エフェクト

**glow-rgbsplit-twitchy.glsl**
- RGB分離と発光効果
- グリッチ風の色分離とグロー

**glitchy.glsl**
- グリッチノイズ効果
- デジタル的な歪みとノイズ

**drunkard.glsl**
- 酔っ払い風の歪み効果
- 画面の揺れと歪み

**sin-interference.glsl**
- サイン波による干渉パターン
- 波状の視覚的干渉

**negative.glsl**
- ネガフィルム風効果
- 色を反転したフィルム風の見た目

**dither.glsl**
- ベイヤーパターンを使ったディザリング効果
- レトロな減色効果

**bloom.glsl**
- ブルーム（発光）効果
- 明るい部分の光の滲み

### アニメーション・動的効果

**animated-gradient-shader.glsl**
- アニメーションするグラデーション背景
- 滑らかに変化する色彩のグラデーション

**matrix-hallway.glsl**
- マトリックス風の緑の雨エフェクト
- 映画「マトリックス」のような文字の雨

**inside-the-matrix.glsl**
- マトリックス内部風エフェクト
- より複雑なマトリックス風の視覚効果

**starfield.glsl**
- 星空エフェクト（白い星）
- 静的な白い星々の背景

**starfield-colors.glsl**
- カラフルな星空エフェクト
- 色とりどりの星々のアニメーション

**fireworks.glsl**
- 花火エフェクト
- 爆発する花火のアニメーション

**fireworks-rockets.glsl**
- ロケット花火エフェクト
- 上昇するロケット花火

**water.glsl**
- 水面の波紋エフェクト
- 水面に広がる波と光の屈折

**underwater.glsl**
- 水中エフェクト
- 水中にいるような光の揺らぎ

**cubes.glsl**
- 3D回転キューブエフェクト
- 3Dキューブが回転するアニメーション

### 特殊効果・テーマ

**cursor_blaze.glsl** ⭐ *現在使用中*
- カーソル移動時の炎のような軌跡エフェクト
- 黄色からオレンジ色の美しい軌跡

**cineShader-Lava.glsl**
- 溶岩のような動的な球体エフェクト
- 流動的な溶岩の質感

**galaxy.glsl**
- 銀河エフェクト
- 宇宙の銀河のような渦巻き

**just-snow.glsl**
- 雪の降るエフェクト
- 静かに舞い散る雪の結晶

**sparks-from-fire.glsl**
- 火花エフェクト
- 火から散る火花のアニメーション

**smoke-and-ghost.glsl**
- 煙とゴーストエフェクト
- 神秘的な煙と幽霊のような効果

**gears-and-belts.glsl**
- 歯車とベルトの機械的エフェクト
- スチームパンク風の機械的な動き

**spotlight.glsl**
- スポットライト効果
- 集中的な光の効果

**gradient-background.glsl**
- グラデーション背景
- 美しいグラデーションの背景色

**mnoise.glsl**
- パーリンノイズベースの効果
- 自然なノイズパターン

## 技術仕様

- すべてのシェーダーはGLSL（OpenGL Shading Language）で記述
- Ghosttyのシェーダーシステムに最適化
- 透明な背景テキスト部分と視覚効果を適切にブレンド
- パフォーマンスを考慮した実装

## ライセンス

各シェーダーファイルには、それぞれのライセンス情報がファイル内に記載されています。使用前に各ファイルのライセンス条項を確認してください。多くのシェーダーは Creative Commons や MIT、パブリックドメインライセンスの下で提供されています。

## カスタマイズ

各シェーダーファイル内の定数値を変更することで、効果の強度や速度を調整できます。例：

```glsl
#define SPEED_MULTIPLIER 1.5  // アニメーション速度
#define COLOR_INTENSITY 0.8   // 色の強度
```

## 貢献

新しいシェーダーの追加や既存シェーダーの改善については、プロジェクトのコントリビューションガイドラインに従ってください。