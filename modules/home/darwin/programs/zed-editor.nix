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
        context = "vim_mode == normal";
        bindings = {
          # --- 🪟 ペイン移動 (Ctrl-g + hjkl) ---
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-j" = "workspace::ActivatePaneDown";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-l" = "workspace::ActivatePaneRight";

          # --- 🪟 ペイン分割 (Ctrl-g + sv) ---
          "ctrl-g s" = "pane::SplitDown";
          "ctrl-g v" = "pane::SplitRight";

          # --- 📑 タブ移動 (Shift + hl) ---
          "shift-h" = "pane::ActivatePreviousItem";
          "shift-l" = "pane::ActivateNextItem";

          # --- 📑 タブ操作 (Ctrl-w) ---
          "ctrl-w q" = "pane::CloseActiveItem";
          "ctrl-w w" = "workspace::Save";

          # --- 🗂 ファイルエクスプローラ開閉 (Space → e) ---
          "space e" = "file_finder::Toggle";

          # --- 💾 保存 (Ctrl + s) ---
          "ctrl-s" = "workspace::Save";
        };
      }
    ];
  };
}
