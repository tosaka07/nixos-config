{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.sheldon = {
    enable = true;
    enableZshIntegration = false;
    enableFishIntegration = false;
    enableBashIntegration = false;
  };

  xdg.configFile."sheldon/plugins.toml".source = ./plugins.toml;
}
