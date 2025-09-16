# Repository Guidelines

## プロジェクト構成 / Module Organization
- ルート: `flake.nix`, `flake.lock`, `README.md`, `AGENTS.md`。
- モジュール: `modules/` 配下に領域別で配置。
  - `modules/darwin/` macOS (nix-darwin) 用設定
  - `modules/home/` home-manager 用設定
  - `modules/hosts/<HOST>/default.nix` ホスト固有
  - `modules/users/<USER>/default.nix` ユーザー固有
- 変更は小さく分割し、各モジュールで `imports = [ ... ];` を用いて組み立てます。

## ビルド / テスト / 開発コマンド
- フレーク更新: `nix flake update` — 依存と入力を更新。
- 定義の検証: `nix flake check` — flake のチェックを実行。
- Darwin 構成ビルド: `nix build .#darwinConfigurations.<HOST>.system`。
- 適用（Taskfile 経由）: `task apply` — 内部で `darwin-rebuild switch --flake .#$(hostname)` を実行。
- 乾式適用: `sudo darwin-rebuild switch --flake .#CA-20033730 --dry-run`。
- ガベコレ: `task gc` / 全削除: `task gc-all`。

## コーディング規約 / Naming Conventions
- 言語: Nix。インデントはスペース2。
- 属性は安定順（入力 → 設定 → 出力）を意識。
- ファイル名はスネーク/ケバブケース（例: `system-defaults.nix`）。
- ホスト/ユーザー固有は各 `modules/hosts/`・`modules/users/` に配置。

## テスト指針
- 変更ごとに `nix flake check` を実行し最小単位で検証。
- 適用前に必ず `--dry-run` で確認。影響が大きい場合はホスト単位で試験適用。
- PR には再現手順・期待結果・確認方法を簡潔に記載。

## コミット / Pull Request ガイドライン
- コミットは Conventional Commits（例: `feat: ...`, `fix: ...`, `chore: ...`）。
- PR には概要、対象ホスト/ユーザー、動作確認結果、関連 Issue、必要に応じてスクショを添付。
- 無関係な変更を混在させず、レビューしやすい粒度で提出。

## セキュリティ / 構成メモ
- 秘密情報はコミットしない。必要時は 1Password 等で秘匿（例: `.env.op`）。
- 非フリー許諾は `NIXPKGS_ALLOW_UNFREE=1` を使用。
- nix 本体は Determinate Nix を想定（`upgrade-nix` タスク）。

## エージェント・自動化向け補足
- 既存スタイルを尊重し最小差分で修正。不要なリネーム/再構成は避ける。
- 反映前に `nix flake check` と乾式適用で安全性を担保。
- 大きな変更はモジュール分割と段階的 PR を推奨。

