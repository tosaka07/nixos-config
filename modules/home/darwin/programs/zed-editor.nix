{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "make"
      "catppuccin"
      "catppuccin-blur"
      "html"
      "dockerfile"
      "sql"
      "lua"
      "terraform"
      "xml"
      "swift"
      "dart"
      "docker-compose"
      "biome"
      "ruff"
      "env"
    ];
    userSettings = {
      theme = "Catppuccin Mocha";
      telemetry = {
        metrics = false;
      };
      vim_mode = true;
      ui_font_size = 12;
      buffer_font_size = 12;
      ui_font_family = "UDEV Gothic 35NF";
      buffer_font_family = "UDEV Gothic 35NF";
    };
    userKeymaps = [
      {
        context = "Editor && vim_mode == normal && vim_operator == none && !VimWaiting";
        bindings = {
          "space e" = "workspace::ToggleLeftDock";
          "space t" = "workspace::ToggleBottomDock";
          "ctrl-s" = "workspace::Save";
        };
      }
      {
        context = "AgentPanel || GitPanel || ProjectPanel || CollabPanel || OutlinePanel || ChatPanel || VimControl || EmptyPane || SharedScreen || MarkdownPreview || KeyContextView || DebugPanel";
        bindings = {
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-l" = "workspace::ActivatePaneRight";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-j" = "workspace::ActivatePaneDown";
        };
      }
    ];
  };
}
