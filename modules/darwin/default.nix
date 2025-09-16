{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./homebrew.nix
    ./system-defaults.nix
    ./activation-scripts.nix
    ./nixpkgs.nix
  ];

  nix.enable = false; # Determinate Nix を使用しているため

  system.configurationRevision = null;

  # Enable fish shell system-wide (Darwin-specific)
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
}

