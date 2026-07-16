{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    (pkgs.writeShellScriptBin "awake" (builtins.readFile ./awake.sh))
  ];
}
