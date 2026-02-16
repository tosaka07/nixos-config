# Marp Skill

Markdownファイルを美しいプレゼンテーションスライド(PDF/PPTX)に変換するMarpのスキルです。

## 概要

このスキルは、Marp CLI を使用して Markdown ファイルをプレゼンテーション形式に変換する方法を提供します。シンプルな Markdown 構文で、プロフェッショナルなスライドを作成できます。

## 使用方法

### 基本的な変換

```bash
# PDFに変換
npx @marp-team/marp-cli slides.md -o output.pdf

# PowerPointに変換
npx @marp-team/marp-cli slides.md -o output.pptx

# HTMLに変換
npx @marp-team/marp-cli slides.md -o output.html
```

### カスタムテーマを使用

```bash
npx @marp-team/marp-cli slides.md --theme custom-theme.css -o output.pdf
```

## ファイル構成

- `SKILL.md` - Marp使用方法の詳細ガイド
- `example.md` - サンプルプレゼンテーション
- `custom-theme.css` - カスタムテーマの例
- `example.pdf` - 生成されたPDF例
- `example-custom.pdf` - カスタムテーマ適用例
- `example.pptx` - 生成されたPowerPoint例

## 主な機能

- **Markdownベース**: 使い慣れたMarkdown構文でスライドを作成
- **複数の出力形式**: PDF, PPTX, HTMLをサポート
- **カスタマイズ可能**: テーマやスタイルを自由にカスタマイズ
- **ライブプレビュー**: ウォッチモードで変更を即座に確認
- **コードハイライト**: プログラミング言語のシンタックスハイライト

## Claude Code での使用

Claude Code が Marp スキルを使用すると、以下のことができます:

1. Markdownからプレゼンテーションを作成
2. カスタムテーマを適用
3. 複数の出力形式に変換
4. プレゼンテーションのレイアウトと設計をサポート

## 要件

- Node.js (v14以降)
- npx または npm

## リソース

- [Marp公式サイト](https://marp.app/)
- [Marpit Framework](https://marpit.marp.app/)
- [GitHub リポジトリ](https://github.com/marp-team/marp-cli)
