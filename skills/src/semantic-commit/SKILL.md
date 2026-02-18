---
name: semantic-commit
description: 変更を意味のある最小単位に分割し Conventional Commits でコミット。Use when: コミット / commit などでコミットを依頼されたとき。
---

# Semantic Commit

変更を分析→論理グループ化→Conventional Commits 形式で順次コミット。git 標準コマンドのみ使用。

## フロー

### 1. 変更分析

```bash
git diff HEAD --name-status   # 変更種別 (A/M/D/R)
git diff HEAD --stat          # 変更規模
git diff HEAD --name-only     # ファイル一覧
```

### 2. グループ化

以下の基準でファイルを論理グループに分割:

- **機能単位**: 同一ディレクトリ/機能に属するファイル群
- **変更種別**: feat / fix / refactor / test / docs / chore を混在させない
- **依存関係**: モデル+マイグレーション、コンポーネント+スタイル等は同一グループ
- **サイズ**: 1コミットあたり10ファイル以下を目安

### 3. コミットメッセージ生成

#### Conventional Commits 形式

```
<type>[(scope)]: <description>
```

**type**: feat / fix / docs / style / refactor / perf / test / chore / build / ci

**スコープ**: 変更の影響範囲（任意）。破壊的変更は `feat!:` のように `!` を付与。

#### プロジェクト規約の検出（優先度順）

1. **CommitLint 設定**: `commitlint.config.*` / `.commitlintrc.*` からカスタム type/scope を読む
2. **既存コミット履歴**: `git log --oneline -30` からパターンを学習
3. **Conventional Commits 標準**: 上記がなければデフォルト

#### 言語判定

`git log --oneline -20` で日本語コミットが50%以上 → 日本語。それ以外 → 英語。

### 4. ユーザー確認

各グループのコミットメッセージとファイル一覧を提示し AskUserQuestion で確認。

### 5. 順次コミット実行

```bash
# グループごとに:
git add <files...>          # 該当ファイルのみステージング
git diff --staged --name-only  # 確認
git commit -m "<message>"   # コミット
```

**署名失敗時は即座に処理を中断する。** プリコミットフック失敗時は最大2回リトライ（自動修正を取り込み）。

### 6. 完了確認

```bash
git status --porcelain       # 未コミット変更の確認
git log --oneline -n 10      # 作成されたコミット一覧
```

自動プッシュは行わない。

## 分割判定

以下のいずれかで「大きな変更」と判定し分割を推奨:
- 5ファイル以上 or 100行以上の変更
- 2つ以上の機能領域にまたがる
- feat + fix + docs 等の混在
