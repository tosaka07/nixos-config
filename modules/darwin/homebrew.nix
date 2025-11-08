{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  homebrew = {
    enable = true;
    user = username;
    onActivation = {
      cleanup = "uninstall";
    };
    brews = [
      "macism"
    ];
    casks = [
      "1password"
      "craft"
      "orbstack"
      "mimestream"
      "cloudflare-warp"
      "karabiner-elements"
      "obs"
      "ghostty"
      "cursor"
      "arc"
      "battery"
      "aqua-voice"
      "shottr"
      "iina"
      "obsidian"
      "discord"
      "raycast"
      "slack"
      "jordanbaird-ice"
      "chatgpt"
      "visual-studio-code"
      "devpod"
      "ollama-app"
      "xcodes-app"
      "microsoft-edge"
      "hammerspoon"
      "microsoft-teams"
      "microsoft-outlook"
      "localsend"
    ];
  };
}
