{
  config,
  lib,
  pkgs,
  ...
}:

{
  # AeroSpace configuration (installed via Homebrew cask)
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };
}
