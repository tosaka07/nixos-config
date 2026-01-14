{
  config,
  lib,
  pkgs,
  claude-code-overlay,
  llm-agents,
  ...
}:
{
  # overlays を適用
  nixpkgs.overlays = [
    claude-code-overlay.overlays.default
    llm-agents.overlays.default
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