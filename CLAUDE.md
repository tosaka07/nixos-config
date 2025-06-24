# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is a NixOS configuration repository for macOS (Darwin) that manages system settings, packages, and dotfiles using Nix flakes. The configuration targets hostname `CA-20033730` for user `y41153`.

## Essential Commands

### Building and Applying Configuration

task apply にはユーザーのパスワードが必要なため、Claude Code 自体はコードを実行せず、ユーザーに手元で実行するよう促してください。

```bash
# Build and apply the complete Nix Darwin configuration
task apply
# or
make apply

# Manual build and apply (equivalent to above)
nix build .#darwinConfigurations.CA-20033730.system --extra-experimental-features 'nix-command flakes'
sudo ./result/sw/bin/darwin-rebuild switch --flake ".#CA-20033730"
```

### Development Tools

The system includes mise for runtime version management. Key tools available:

-   `mise` - Runtime version manager (configured in `modules/home/base/programs/mise/mise.nix`)
-   `task` - Task runner (alias: `t`)
-   `nixfmt-rfc-style` - Nix code formatting

## Architecture

### Core Structure

-   `flake.nix` - Main flake configuration with inputs and Darwin system definition
-   `modules/` - Modular configuration components
    -   `home/base/programs/` - Cross-platform program configurations
        -   `fish/` - Fish shell configuration with custom functions and aliases
        -   `mise/` - Development environment configuration
        -   `git/` - Git configuration
        -   `ssh/` - SSH configuration
    -   `home/darwin/programs/` - macOS-specific program configurations
        -   `ghostty/` - Ghostty terminal emulator configuration

### Package Management

The system uses multiple package sources:

-   Nix packages (primary source)
-   Homebrew casks (managed via nix-homebrew)
-   brew-nix for direct Homebrew package integration

### Key Modules

-   **nix-darwin**: macOS system configuration
-   **home-manager**: User environment and dotfile management
-   **nix-homebrew**: Homebrew integration
-   **brew-nix**: Direct Homebrew package access

### Module Arguments Handling

This configuration passes system-specific values (`hostname`, `username`, `system`) directly to modules. The consistent pattern is:

1. **Direct declaration**: Modules that need these values must explicitly declare them in their first parameter set
2. **Explicit passing**: When importing modules, always pass these arguments explicitly using `import ./module { inherit hostname username system; }`
3. **No implicit usage**: Never rely on these variables being available through `specialArgs` or module system magic

Example:
```nix
{ hostname, username, system }:
{ config, lib, pkgs, ... }:
{
  # Module configuration using hostname, username, system
}
```

### Shell Environment

Fish shell is configured with:

-   Tide prompt (auto-configured during home-manager activation)
-   Custom key bindings for directory navigation (Shift+arrows)
-   FZF integration for fuzzy searching
-   Custom functions for git branch switching, ghq repository navigation
-   AI-powered commit message generation (`aicommit` function)

### Development Environment

mise manages development runtimes including:

-   Node.js 20.11.0, Flutter 3.16.5-stable, Go, Python, Rust
-   Claude Code integration via Vertex AI (configured in mise.nix)

### System Defaults

The configuration sets opinionated macOS defaults including:

-   Dark mode interface
-   Show file extensions and hidden files
-   Custom dock settings (auto-hide, small icons)
-   Trackpad tap-to-click and three-finger drag
-   CapsLock remapped to Control
-   Custom screenshot settings (JPG format, custom location)
