{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Ghosttyの設定ファイルのみを管理（パッケージはbrewCasksから）
  xdg.configFile."ghostty/config".text = ''
    theme = Catppuccin Mocha
    font-size = 11
    font-family = UDEV Gothic 35NF
    font-feature = -calt
    font-feature = -liga
    font-feature = -dlig
    background-opacity = 0.88
    background-blur-radius = 20
    quit-after-last-window-closed = true
    window-padding-x = 8
    window-padding-y = 8
    keybind = shift+enter=text:\n
    keybind = global:ctrl+grave_accent=toggle_quick_terminal
    macos-titlebar-style = hidden
    custom-shader = shaders/cursor_blaze.glsl
  '';

  # Ghostty shaders フォルダのコピー
  xdg.configFile."ghostty/shaders" = {
    source = ./shaders;
    recursive = true;
  };
}
