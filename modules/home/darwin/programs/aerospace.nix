{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.aerospace = {
    enable = true;
    userSettings = {
      after-startup-command = [
        # "exec-and-forget borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=4.0"
      ];
      exec-on-workspace-change = [ ];
      start-at-login = false;
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      accordion-padding = 40;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      # on-focus-changed = [
      #   "exec-and-forget macism com.google.inputmethod.Japanese.Roman"
      # ];
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
      automatically-unhide-macos-hidden-apps = true;

      key-mapping = {
        preset = "qwerty";
      };

      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 16;
        outer.bottom = 16;
        outer.top = 16;
        outer.right = 16;
      };

      mode.main.binding = {
        ctrl-space = [ "mode switch" ];
        cmd-h = [ ]; # Disable "hide application"
        cmd-alt-h = [ ]; # Disable "hide others"
        f19 = [ "mode switch" ]; # Use F19 as a fallback for mode switch

        # Hyper Key (cmd-alt-ctrl-shift)
        cmd-alt-ctrl-shift-space = [ "workspace-back-and-forth" ];
        cmd-alt-ctrl-shift-1 = [ "workspace 1" ];
        cmd-alt-ctrl-shift-2 = [ "workspace 2" ];
        cmd-alt-ctrl-shift-3 = [ "workspace 3" ];
        cmd-alt-ctrl-shift-4 = [ "workspace 4" ];
        cmd-alt-ctrl-shift-5 = [ "workspace 5" ];
        cmd-alt-ctrl-shift-6 = [ "workspace 6" ];
        cmd-alt-ctrl-shift-7 = [ "workspace 7" ];
        cmd-alt-ctrl-shift-8 = [ "workspace 8" ];
        cmd-alt-ctrl-shift-9 = [ "workspace 9" ];
        cmd-alt-ctrl-shift-0 = [ "workspace 0" ];
        cmd-alt-ctrl-shift-h = [ "focus left" ];
        cmd-alt-ctrl-shift-j = [ "focus down" ];
        cmd-alt-ctrl-shift-k = [ "focus up" ];
        cmd-alt-ctrl-shift-l = [ "focus right" ];
        cmd-alt-ctrl-shift-z = [
          "fullscreen"
          "mode main"
        ];
        cmd-alt-ctrl-shift-t = [
          "layout tiles horizontal vertical"
          "mode main"
        ];
        cmd-alt-ctrl-shift-a = [
          "layout accordion horizontal vertical"
          "mode main"
        ];
        cmd-alt-ctrl-shift-f = [
          "layout floating tiling"
          "mode main"
        ];
      };

      mode.switch.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
        backspace = [
          "reload-config"
          "mode main"
        ];
        space = [
          "workspace-back-and-forth"
          "mode main"
        ];
        ctrl-space = [
          "workspace-back-and-forth"
          "mode main"
        ];

        "1" = [
          "workspace 1"
          "mode main"
        ];
        "2" = [
          "workspace 2"
          "mode main"
        ];
        "3" = [
          "workspace 3"
          "mode main"
        ];
        "4" = [
          "workspace 4"
          "mode main"
        ];
        "5" = [
          "workspace 5"
          "mode main"
        ];
        "6" = [
          "workspace 6"
          "mode main"
        ];
        "7" = [
          "workspace 7"
          "mode main"
        ];
        "8" = [
          "workspace 8"
          "mode main"
        ];
        "9" = [
          "workspace 9"
          "mode main"
        ];
        "0" = [
          "workspace 0"
          "mode main"
        ];

        h = [
          "focus left"
          "mode main"
        ];
        j = [
          "focus down"
          "mode main"
        ];
        k = [
          "focus up"
          "mode main"
        ];
        l = [
          "focus right"
          "mode main"
        ];

        ctrl-h = [
          "workspace prev"
          "mode main"
        ];
        ctrl-l = [
          "workspace next"
          "mode main"
        ];
        ctrl-j = [
          "focus-monitor next"
          "mode main"
        ];
        ctrl-k = [
          "focus-monitor prev"
          "mode main"
        ];

        w = [ "mode window" ];

        x = [
          "close"
          "mode main"
        ];
        shift-x = [
          "close-all-windows-but-current"
          "mode main"
        ];
        z = [
          "fullscreen"
          "mode main"
        ];

        p = [
          "workspace prev"
          "mode main"
        ];
        n = [
          "workspace next"
          "mode main"
        ];
      };

      mode.window.binding = {
        esc = [ "mode main" ];
        backspace = [ "mode switch" ];

        h = [
          "move left"
          "mode main"
        ];
        j = [
          "move down"
          "mode main"
        ];
        k = [
          "move up"
          "mode main"
        ];
        l = [
          "move right"
          "mode main"
        ];

        shift-h = [
          "join-with left"
          "mode main"
        ];
        shift-j = [
          "join-with down"
          "mode main"
        ];
        shift-k = [
          "join-with up"
          "mode main"
        ];
        shift-l = [
          "join-with right"
          "mode main"
        ];

        "1" = [
          "move-node-to-workspace 1"
          "mode main"
        ];
        "2" = [
          "move-node-to-workspace 2"
          "mode main"
        ];
        "3" = [
          "move-node-to-workspace 3"
          "mode main"
        ];
        "4" = [
          "move-node-to-workspace 4"
          "mode main"
        ];
        "5" = [
          "move-node-to-workspace 5"
          "mode main"
        ];
        "6" = [
          "move-node-to-workspace 6"
          "mode main"
        ];
        "7" = [
          "move-node-to-workspace 7"
          "mode main"
        ];
        "8" = [
          "move-node-to-workspace 8"
          "mode main"
        ];
        "9" = [
          "move-node-to-workspace 9"
          "mode main"
        ];
        "0" = [
          "move-node-to-workspace 0"
          "mode main"
        ];

        t = [
          "layout tiles horizontal vertical"
          "mode main"
        ];
        a = [
          "layout accordion horizontal vertical"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];

        m = [
          "move-node-to-monitor --wrap-around next"
          "mode main"
        ];
        shift-m = [
          "move-workspace-to-monitor --wrap-around next"
          "mode main"
        ];

        minus = "resize smart -50";
        shift-equal = "resize smart +50";
        equal = [
          "balance-sizes"
          "mode main"
        ];

        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
      };

      on-window-detected = [
        {
          "if".app-id = "com.tinyspeck.slackmacgap";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.mimestream.Mimestream";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.hnc.Discord";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.apple.Safari";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "company.thebrowser.Browser";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.apple.finder";
          run = "layout floating";
        }
        {
          "if".app-id = "com.1password.1password";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.ActivityMonitor";
          run = "layout floating";
        }
        {
          "if".app-id = "us.zoom.xos";
          run = "layout floating";
        }
        {
          "if".app-id = "com.bitwarden.desktop";
          run = "layout floating";
        }
        {
          "if".app-id = "com.openai.chat";
          run = "layout floating";
        }
        {
          "if".app-id = "company.thebrowser.Browser";
          check-further-callbacks = true;
          run = "layout floating";
        }
        {
          "if" = {
            app-id = "company.thebrowser.Browser";
            window-title-regex-substring = "^(?!Space)";
          };
          check-further-callbacks = true;
          run = "layout tiling";
        }
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = "layout tiling";
        }
      ];

      workspace-to-monitor-force-assignment = {
        "1" = "main";
        "2" = "main";
        "3" = "main";
        "4" = "main";
        "5" = "main";
        "6" = "main";
        "7" = "main";
        "8" = "^DeskPad Display";
        "9" = "secondary";
        "0" = "secondary";
      };
    };
  };
}
