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
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # GUI applications for macOS
  home.packages = with pkgs; [
    firefox
    zoom-us
    discord
    raycast
    xcodes
    slack
    ice-bar
    chatgpt
    vscode
    aerospace
    brewCasks.ghostty
    brewCasks.obs
    brewCasks.cursor
    brewCasks.arc
    brewCasks.battery
    brewCasks.aqua-voice
  ];
}
