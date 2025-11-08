{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."karabiner/karabiner.json".text = builtins.toJSON {
    profiles = [
      {
        name = "Default";
        complex_modifications = {
          rules = [
            # Space 単押し=Space, 長押し=F19
            # {
            #   description = "Tap spacebar → space, hold spacebar → F19";
            #   manipulators = [
            #     {
            #       type = "basic";
            #       from = {
            #         key_code = "spacebar";
            #         modifiers = {
            #           mandatory = [ ];
            #         };
            #       };
            #       to_if_alone = [
            #         { key_code = "spacebar"; }
            #       ];
            #       to_if_held_down = [
            #         {
            #           key_code = "f19";
            #           repeat = false;
            #         }
            #       ];
            #       parameters = {
            #         "basic.to_if_held_down_threshold_milliseconds" = 200;
            #       };
            #     }
            #   ];
            # }

            # 追加: Left Command 単押しで Hyper(⌃⌥⇧⌘) をトグル
            #      長押し・同時押しでは通常の ⌘
            # {
            #   description = "Left Command tap => toggle sticky Hyper; hold/chord => normal ⌘";
            #   manipulators = [
            #     {
            #       type = "basic";
            #       from = {
            #         key_code = "left_command";
            #         modifiers = {
            #           optional = [ "any" ];
            #         };
            #       };
            #       # 同時押し・長押し時は普通の ⌘
            #       to = [
            #         {
            #           key_code = "left_command";
            #           lazy = true;
            #         }
            #       ];
            #       # 単押し時は Hyper をトグル（sticky_modifier）
            #       to_if_alone = [
            #         {
            #           sticky_modifier = {
            #             left_control = "toggle";
            #           };
            #         }
            #         {
            #           sticky_modifier = {
            #             left_option = "toggle";
            #           };
            #         }
            #         {
            #           sticky_modifier = {
            #             left_shift = "toggle";
            #           };
            #         }
            #         {
            #           sticky_modifier = {
            #             left_command = "toggle";
            #           };
            #         }
            #       ];
            #     }
            #   ];
            # }
          ];
        };
        virtual_hid_keyboard = {
          keyboard_type_v2 = "ansi";
        };
      }
    ];
  };
}
