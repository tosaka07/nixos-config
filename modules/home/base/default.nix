{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./programs/fish/fish.nix
    ./programs/atuin.nix
    ./programs/bat.nix
    ./programs/git.nix
    ./programs/gitui.nix
    ./programs/mise.nix
    ./programs/ssh.nix
  ];

  # Allow unfree packages for this user
  nixpkgs.config.allowUnfree = true;

  # Common CLI packages for all systems
  home.packages = with pkgs; [
    jq
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
    trash-cli

    # fonts
    udev-gothic-nf
    plemoljp-nf
  ];
}
