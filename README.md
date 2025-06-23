# nixos-config

Nixos, Nix Package Manager の設定をまとめたものです。

## Tools

-   Nix Package Manager
-   [nix-darwin](https://github.com/LnL7/nix-darwin)
-   [home-manager](https://github.com/nix-community/home-manager)
-   [Determinate Nix](https://determinate.systems/posts/determinate-nix-installer)

## Setup (macOS/Darwin)

Nix をインストールします。Nix 公式ではなく、[nix-installer](https://github.com/DeterminateSystems/nix-installer#skip-confirmation)を推奨します。

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

設定を反映させますが、既存のファイルが存在すると書き込みエラーが発生するためバックアップを取ります。

```
mv /etc/nix/nix.conf /etc/nix/nix.conf.bk
mv /etc/shells /etc/shells.bk
```

初回は `task` コマンドがないため、以下のコマンドで設定を適用します。

```sh
nix shell nixpkgs#go-task -c task apply
```

以降は以下のコマンドで設定を適用できます。

```sh
task apply
```

現状、ログインシェルの変更は手動で行わないといけないっぽいのです。

```sh
chsh -s /run/current-system/sw/bin/fish
```

## フォルダ構成

```
.
├── flake.nix              # メインのflake設定
├── flake.lock             # ロックされた依存関係
├── Taskfile.yaml          # タスクランナー設定
├── CLAUDE.md              # Claude Code用の指示書
└── modules/
    ├── darwin/            # macOS固有のシステム設定
    │   ├── default.nix    # メインのDarwin設定
    │   ├── homebrew.nix   # Homebrewパッケージとcasks
    │   ├── system-defaults.nix    # macOSシステム設定
    │   ├── activation-scripts.nix # defaultsコマンド用のactivationフック
    │   └── nixpkgs.nix    # Nixpkgs設定（allowUnfree）
    ├── home/              # Home-manager設定
    │   ├── base/          # 全システム共通のhome設定
    │   │   ├── default.nix        # 基本パッケージとインポート
    │   │   └── shell/             # シェル設定
    │   │       ├── fish/          # Fishシェル設定
    │   │       ├── git/           # Git設定
    │   │       ├── ssh/           # SSH設定
    │   │       └── mise/          # Mise（ランタイムマネージャー）設定
    │   └── darwin/        # macOS固有のhome設定
    │       └── default.nix        # macOS用GUIアプリケーション
    ├── hosts/             # ホスト固有の設定
    │   └── CA-20033730/   # 特定のホスト名用設定
    │       └── default.nix
    ├── users/             # ユーザー固有の設定
    │   ├── base.nix       # 共通ユーザーシステム設定
    │   └── y41153/        # 特定ユーザー設定
    │       └── default.nix
    └── shared/            # 共有ヘルパーモジュール
        └── mkDarwinSystem.nix    # Darwinシステム作成用ヘルパー関数
```

## 利用可能なタスク

```bash
# Nix Darwin設定を適用
task apply

# 手動ガベージコレクション（Determinate Nixが自動管理）
task gc      # 30日以上古い世代を削除
task gc-all  # すべての古い世代を削除（現在の世代のみ保持）
```

## 主な機能

- **Determinate Nix統合**: 
  - 自動ガベージコレクション
  - Fishシェル補完
  - 優れたNix体験をすぐに利用可能
- **Fishシェル**: Tideプロンプトと便利なプラグイン設定済み
- **開発ツール**: mise、git、neovim、各種CLIツール
- **macOSデフォルト設定**: システム環境設定の自動構成
- **Homebrew統合**: formulaとcaskをNixで管理

## Mac 設定

ここから変更可能な設定を一覧で見ることができます。

https://daiderd.com/nix-darwin/manual/index.html#sec-options

## Uninstall

nix-installer を使用している場合は以下でアンインストールできます。

```sh
/nix/nix-installer uninstall
```