{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.atuin = {
    enable = true;
    settings = {
      enter_accept = false;
      sync.records = true;
    };
  };
}
