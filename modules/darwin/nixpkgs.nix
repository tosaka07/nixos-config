{
  config,
  lib,
  pkgs,
  system,
  claude-code-overlay,
  llm-agents,
  ...
}:
{
  # overlays を適用
  nixpkgs.overlays = [
    claude-code-overlay.overlays.default
    # llm-agents は packages のみ提供するため、overlay を自作
    (final: prev: {
      ccusage = llm-agents.packages.${system}.ccusage;
    })
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