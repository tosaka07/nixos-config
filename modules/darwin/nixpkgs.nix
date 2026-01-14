{
  config,
  lib,
  pkgs,
  claude-code-overlay,
  ...
}:
{
  # overlays を適用
  nixpkgs.overlays = [
    claude-code-overlay.overlays.default
    (import ../../overlays)
  ];

  # unfree パッケージを個別に許可
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [
      "claude"
      "ngrok"
      "1password-cli"
    ];
}