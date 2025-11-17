# nixos-config

Nixos, Nix Package Manager の設定をまとめたものです。

## Tools

-   Nix Package Manager
-   [nix-darwin](https://github.com/LnL7/nix-darwin)
-   [home-manager](https://github.com/nix-community/home-manager)
-   [Determinate Nix](https://determinate.systems/posts/determinate-nix-installer)

## Setup (macOS/Darwin)

### 1. リポジトリのクローン

まず、このリポジトリをクローンします。

```sh
git clone https://github.com/tosaka07/nixos-config.git
cd nixos-config
```

### 2. Nix のインストール

Nix をインストールします。Nix 公式ではなく、[nix-installer](https://github.com/DeterminateSystems/nix-installer#skip-confirmation)を推奨します。

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 3. 既存設定ファイルのバックアップ

設定を反映させますが、既存のファイルが存在すると書き込みエラーが発生するためバックアップを取ります。

```sh
mv /etc/nix/nix.conf /etc/nix/nix.conf.bk
mv /etc/shells /etc/shells.bk
```

### 4. 設定の適用

初回は `task` コマンドがないため、以下のコマンドで設定を適用します。

```sh
nix shell nixpkgs#go-task -c task apply
```

以降は以下のコマンドで設定を適用できます。

```sh
task apply
```

### 5. ログインシェルの変更

現状、ログインシェルの変更は手動で行う必要があります。

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
    │   │   └── programs/          # プログラム設定
    │   │       ├── fish/          # Fishシェル設定
    │   │       ├── git/           # Git設定
    │   │       ├── ssh/           # SSH設定
    │   │       └── mise/          # Mise（ランタイムマネージャー）設定
    │   └── darwin/        # macOS固有のhome設定
    │       ├── default.nix        # macOS用GUIアプリケーション
    │       └── programs/          # macOS専用プログラム設定
    │           └── ghostty/       # Ghosttyターミナル設定
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

## 新しいマシン・ユーザーの追加方法

### 新しいマシン（ホスト）を追加する

1. **ホスト名を確認**

```bash
hostname
# 例: MacBook-Pro
```

2. **ホスト固有の設定ファイルを作成**

```bash
mkdir -p modules/hosts/<hostname>
```

`modules/hosts/<hostname>/default.nix` を作成：

```nix
{
  hostname,
  username,
  system,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ホスト固有の設定のみ記述
  system.stateVersion = 6;
  networking.hostName = hostname;
  system.primaryUser = username;

  # このホスト固有の追加設定があれば記述
  # 例: SSH設定、特殊なハードウェア設定など
}
```

3. **flake.nix に新しいマシンを登録**

`flake.nix` の `darwinConfigurations` に追加：

```nix
darwinConfigurations = {
  "CA-20033730" = mkDarwinSystem {
    hostname = "CA-20033730";
    username = "y41153";
    system = "aarch64-darwin";
  };

  # 新しいマシンを追加
  "<hostname>" = mkDarwinSystem {
    hostname = "<hostname>";
    username = "<username>";
    system = "aarch64-darwin";  # Apple Silicon の場合
    # system = "x86_64-darwin";  # Intel Mac の場合
  };
};
```

4. **設定を適用**

```bash
task apply
```

### 新しいユーザーを追加する

既存のマシンに別のユーザーを追加する場合、または新しいユーザー固有の設定が必要な場合：

1. **ユーザー固有の設定ファイルを作成**

```bash
mkdir -p modules/users/<username>
```

`modules/users/<username>/default.nix` を作成：

```nix
{
  hostname,
  username,
  system,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (import ../../home/darwin { inherit hostname username system; })
  ];

  # ユーザー固有の追加設定があれば記述
}
```

2. **mkDarwinSystem.nix でユーザーモジュールを読み込む**

`modules/shared/mkDarwinSystem.nix` で、新しいユーザーのモジュールがインポートされるように確認します。
通常は自動的に `modules/users/${username}/default.nix` が読み込まれます。

3. **flake.nix で新しいユーザーを使用するマシンを定義**

```nix
darwinConfigurations = {
  "<hostname>" = mkDarwinSystem {
    hostname = "<hostname>";
    username = "<new-username>";
    system = "aarch64-darwin";
  };
};
```

### 注意事項

- **ホスト名**: `$(hostname)` で取得される値を使用してください
- **システムアーキテクチャ**:
  - Apple Silicon (M1/M2/M3): `aarch64-darwin`
  - Intel Mac: `x86_64-darwin`
- **共通設定**: ユーザー共通の設定は `modules/users/base.nix` に記述
- **ホスト固有設定**: そのマシンでのみ必要な設定を `modules/hosts/<hostname>/` に記述
- **ユーザー固有設定**: そのユーザーでのみ必要な設定を `modules/users/<username>/` に記述

### 設定の構造

```
マシン構成 = 共通設定 + ホスト固有設定 + ユーザー固有設定
            (darwin/)  (hosts/<hostname>/)  (users/<username>/)
```

## 主な機能

-   **Determinate Nix 統合**:
    -   自動ガベージコレクション
    -   Fish シェル補完
    -   優れた Nix 体験をすぐに利用可能
-   **Fish シェル**: Tide プロンプトと便利なプラグイン設定済み
-   **開発ツール**: mise、git、neovim、各種 CLI ツール
-   **macOS デフォルト設定**: システム環境設定の自動構成
-   **Homebrew 統合**: formula と cask を Nix で管理

## Mac 設定

ここから変更可能な設定を一覧で見ることができます。

https://daiderd.com/nix-darwin/manual/index.html#sec-options

## Uninstall

nix-installer を使用している場合は以下でアンインストールできます。

```sh
/nix/nix-installer uninstall
```
