{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./shell/fish/fish.nix
    ./shell/mise/mise.nix
    ./shell/git/git.nix
    ./shell/ssh/ssh.nix
  ];

  # Allow unfree packages for this user
  nixpkgs.config.allowUnfree = true;

  # Common CLI packages for all systems
  home.packages = with pkgs; [
    jq
    fzf
    fd
    ripgrep
    bat
    eza
    atuin
    starship
    zoxide
    neovim
    git
    delta
    gitui
    gh
    ghq
    go-task
    nixfmt-rfc-style
    google-cloud-sdk
    trash-cli
    mise
  ];
}
