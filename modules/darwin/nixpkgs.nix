{
  config,
  lib,
  pkgs,
  gwm,
  ...
}:
{
  # overlays を適用
  nixpkgs.overlays = [
    (import ../../overlays)
    gwm.overlays.default
  ];

  # unfree パッケージを個別に許可
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [
      "claude"
      "ngrok"
      "1password-cli"
    ];
}