{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Ghosttyの設定ファイルのみを管理（パッケージはbrewCasksから）
  xdg.configFile."ghostty/config".text = ''
    theme = catppuccin-mocha
    font-size = 10
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
  '';
}
