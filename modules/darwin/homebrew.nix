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
      autoUpdate = false;
      upgrade = false;
    };
    brews = [
      "macism"
      "k1low/tap/mo"
    ];
    casks = [
      "yashiki"
      "aerospace"
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
      "google-chrome"
      "microsoft-edge"
      "hammerspoon"
      "microsoft-teams"
      "microsoft-outlook"
      "localsend"
      "chatgpt-atlas"
      "postman"
      "claude"
      "adobe-creative-cloud"
      "spotify"
      "drawio"
      "codex-app-TEMP_REMOVE"
      "godot-TEMP_REMOVE"
    ];
  };
}
