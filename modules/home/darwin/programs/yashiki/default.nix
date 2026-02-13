{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Yashiki configuration (installed via Homebrew cask)
  xdg.configFile."yashiki/init" = {
    source = ./init;
    executable = true;
  };
}
