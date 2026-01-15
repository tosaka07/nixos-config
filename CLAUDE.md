# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is a Nix Darwin configuration repository for macOS that manages system settings, packages, and dotfiles using Nix flakes with Determinate Nix. The configuration dynamically detects the hostname using `$(hostname)` for flexibility.

## Essential Commands

### Building and Applying Configuration

**Important**: `task apply` requires sudo privileges. Claude Code cannot execute this directly - prompt the user to run it locally.

```bash
# Primary method - Build and apply Darwin configuration
task apply

# Alternative commands available
task gc          # Garbage collection (delete generations older than 30 days)
task gc-all      # Delete all old generations (keep only current)
task update      # Update all flake inputs
task update-nixpkgs  # Update only nixpkgs
task upgrade-nix     # Upgrade Determinate Nix

# Manual equivalent of task apply
nix build .#darwinConfigurations.$(hostname).system --extra-experimental-features 'nix-command flakes'
sudo ./result/sw/bin/darwin-rebuild switch --flake ".#$(hostname)"
```

## Architecture

### Module System Pattern

This configuration uses a consistent pattern for passing system parameters (`hostname`, `username`, `system`) to modules:

1. **mkDarwinSystem helper** (`modules/shared/mkDarwinSystem.nix`): Factory function that creates Darwin systems
2. **Direct parameter passing**: Modules explicitly declare and receive parameters
3. **Module imports**: Always use `import ./module { inherit hostname username system; }`

Example module structure:
```nix
# First parameter set: system parameters
{ hostname, username, system }:
# Second parameter set: standard Nix module arguments
{ config, lib, pkgs, ... }:
{
  # Module configuration
}
```

### Custom Overlays

カスタムパッケージは `overlays/` ディレクトリで管理する。llm-agents.nix 風の構造を採用。

```
overlays/
├── default.nix           # overlay エントリポイント
└── gwq/                   # パッケージディレクトリ
    ├── hashes.json        # version, hash, vendorHash
    ├── default.nix        # パッケージ定義
    └── update.py          # 更新スクリプト
```

#### パッケージ構造

各パッケージは `overlays/<package-name>/` ディレクトリに配置：

1. **`hashes.json`** - バージョンとハッシュを分離管理
   ```json
   {
     "version": "0.0.7",
     "hash": "sha256-...",
     "vendorHash": "sha256-..."
   }
   ```

2. **`default.nix`** - hashes.json を読み込むパッケージ定義
   ```nix
   let
     hashes = lib.importJSON ./hashes.json;
   in
   buildGoModule rec {
     inherit (hashes) version;
     # ...
   }
   ```

3. **`update.py`** - GitHub API から最新バージョンを取得して更新
   ```bash
   nix-shell -p python3 nix-prefetch-github --run "python overlays/gwq/update.py"
   ```

#### 新しいパッケージの追加手順

1. `overlays/<package-name>/` ディレクトリを作成
2. `overlays/<package-name>/hashes.json` を作成
3. `overlays/<package-name>/default.nix` を作成
4. `overlays/<package-name>/update.py` を作成
5. `overlays/default.nix` に属性を追加
6. `modules/home/base/default.nix` の `home.packages` に追加
7. `.github/workflows/update-packages.yml` の `matrix.package` に追加

### Directory Structure

```
modules/
├── darwin/              # macOS system-level configuration
│   ├── default.nix      # Main Darwin module entry point
│   ├── homebrew.nix     # Homebrew packages and casks management
│   ├── system-defaults.nix  # macOS defaults (Dock, Finder, etc.)
│   ├── activation-scripts.nix  # System activation hooks
│   └── nixpkgs.nix      # Nixpkgs configuration
├── home/                # User environment configuration
│   ├── base/            # Cross-platform home configurations
│   │   ├── default.nix  # Base packages and imports
│   │   └── programs/    # Program configurations (fish, git, mise, tmux, etc.)
│   └── darwin/          # macOS-specific home configurations
│       ├── default.nix  # GUI applications and macOS tools
│       └── programs/    # macOS-specific programs (ghostty, aerospace, karabiner, zed)
├── hosts/               # Host-specific configurations
│   └── CA-20033730/     # Example host configuration
├── users/               # User-specific configurations
│   ├── base.nix         # Common user system settings
│   └── y41153/          # Example user configuration
└── shared/              # Shared utilities
    └── mkDarwinSystem.nix  # Darwin system builder function
```

### Key Technologies

- **Determinate Nix**: Enhanced Nix installer with auto-GC and improved UX
- **nix-darwin**: macOS system configuration management
- **home-manager**: User environment and dotfile management
- **nix-homebrew**: Declarative Homebrew package management through Nix

### Development Environment

- **Shell**: Fish with Tide prompt, custom functions, and FZF integration
- **Runtime Management**: mise for Node.js, Python, Go, Rust, Flutter
- **Terminal**: Ghostty, tmux, zellij configurations
- **Editor Integration**: Zed Editor, gitui configurations
- **Task Runner**: go-task (aliased as `t`)
