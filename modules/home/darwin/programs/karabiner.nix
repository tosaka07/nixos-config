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
            {
              description = "Tap spacebar → space, hold spacebar → F19";
              manipulators = [
                {
                  type = "basic";
                  from = {
                    key_code = "spacebar";
                    modifiers = {
                      optional = [ "any" ];
                    };
                  };
                  to_if_alone = [
                    {
                      key_code = "spacebar";
                    }
                  ];
                  to_if_held_down = [
                    {
                      key_code = "f19";
                    }
                  ];
                  parameters = {
                    "basic.to_if_held_down_threshold_milliseconds" = 130;
                  };
                }
              ];
            }
          ];
        };
        virtual_hid_keyboard = {
          keyboard_type_v2 = "ansi";
        };
      }
    ];
  };
}
