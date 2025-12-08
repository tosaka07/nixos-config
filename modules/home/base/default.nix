{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./programs/fish/fish.nix
    ./programs/zellij/zellij.nix
    ./programs/atuin.nix
    ./programs/bat.nix
    ./programs/git.nix
    ./programs/gitui.nix
    ./programs/mise.nix
    ./programs/ssh.nix
    ./programs/sheldon.nix
    ./programs/tmux/tmux.nix
    ./programs/zsh/default.nix
    ./programs/zsh/zeno.nix
  ];

  # Common CLI packages for all systems
  home.packages = with pkgs; [
    jq
    yq
    fzf
    fd
    ripgrep
    eza
    atuin
    starship
    zoxide
    neovim
    delta
    gh
    ghq
    go-task
    nixfmt-rfc-style
    google-cloud-sdk
    gomi
    zellij
    glow
    ngrok
    yt-dlp
    difftastic
    hyperfine
    ghostscript
    _1password-cli
    ffmpeg
    devcontainer
    dasel
    codex
    claude-code
    yazi
    lazygit

    # languages
    nixd
    nil

    # fonts
    udev-gothic-nf
    plemoljp-nf
  ];
}
