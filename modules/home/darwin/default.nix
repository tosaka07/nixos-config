{
  hostname,
  username,
  system,
}:
{
  config,
  pkgs,
  lib,
  ...
}@args:
{
  imports = [
    ../base
    ./programs/ghostty/ghostty.nix
    ./programs/aerospace
    ./programs/karabiner.nix
    # ./programs/zed-editor.nix
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # GUI applications for macOS
  home.packages = with pkgs; [
    terminal-notifier
    # zoom-us
    # discord
    # raycast
    # xcodes
    # slack
    # ice-bar
    # chatgpt
    # vscode
  ];
}
