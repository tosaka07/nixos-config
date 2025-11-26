{
  config,
  lib,
  pkgs,
  claude-code-overlay,
  ...
}:
{
  # claude-code-overlay を適用
  nixpkgs.overlays = [
    claude-code-overlay.overlays.default
  ];

  # unfree パッケージを個別に許可
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [
      "claude"
      "ngrok"
      "1password-cli"
    ];
}