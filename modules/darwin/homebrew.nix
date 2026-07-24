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
    taps = [
      "homebrew/cask"
      {
        name = "typester/yashiki";
        trusted = true;
      }
      {
        name = "nikitabobko/tap";
        trusted = true;
      }
      {
        name = "k1low/tap";
        trusted = true;
      }
    ];
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
      "postman"
      "claude"
      "adobe-creative-cloud"
      "spotify"
      "drawio"
      "codex-app"
      "godot"
    ];
  };
}
