{
  config,
  lib,
  pkgs,
  ...
}:
{
  # システムレベルでunfreeパッケージを許可
  nixpkgs.config.allowUnfree = true;
}