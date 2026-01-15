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

カスタムパッケージは `overlays/` ディレクトリで管理する。

```
overlays/
├── default.nix     # overlay エントリポイント（属性名を定義）
└── gwq.nix         # パッケージ定義
```

#### 命名規則

**重要**: 以下の3箇所で名前を一致させる必要がある：

1. **`overlays/default.nix` の属性名** - nix-update が参照する名前
   ```nix
   final: prev: {
     gwq = prev.callPackage ./gwq.nix { };  # ← "gwq" が属性名
   }
   ```

2. **`.github/workflows/update-packages.yml` の matrix.package**
   ```yaml
   matrix:
     package:
       - gwq  # ← 属性名と一致
   ```

3. **パッケージファイル名** (`overlays/gwq.nix`) - 属性名と一致させる（推奨）

4. **`flake.nix` の packages output** - nix-update が参照
   ```nix
   packages = forAllSystems (pkgs: {
     gwq = pkgs.callPackage ./overlays/gwq.nix { };  # ← 属性名と一致
   });
   ```

#### 新しいパッケージの追加手順

1. `overlays/<package-name>.nix` を作成
2. `overlays/default.nix` に属性を追加
3. `flake.nix` の `packages` output に追加（nix-update 用）
4. `modules/home/base/default.nix` の `home.packages` に追加
5. `.github/workflows/update-packages.yml` の `matrix.package` に追加

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
