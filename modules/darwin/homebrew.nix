{
  config,
  lib,
  pkgs,
  ...
}:
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
    };
    casks = [
      "1password"
      "craft"
      "orbstack"
      "mimestream"
      "cloudflare-warp"
      "karabiner-elements"
    ];
  };
}
