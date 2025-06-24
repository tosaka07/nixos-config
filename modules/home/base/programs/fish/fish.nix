{
  config,
  lib,
  pkgs,
  ...
}:
let
  catppuccin-fish = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "6a85af2ff722ad0f9fbc8424ea0a5c454661dfed";
    sha256 = "Oc0emnIUI4LV7QJLs4B2/FQtCFewRFVp7EDv8GawFsA=";
  };
in
{
  xdg.configFile."fish/themes/Catppuccin Mocha.theme".source =
    "${catppuccin-fish}/themes/Catppuccin Mocha.theme";

  # Darwin-specific home configuration
  home.activation.configure-tide = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Dotted --prompt_spacing=Compact --icons='Many icons' --transient=No"
  '';

  programs.fish = {
    enable = true;
    plugins = with pkgs.fishPlugins; [
      {
        name = "fzf";
        src = fzf-fish.src;
      }
      {
        name = "tide";
        src = tide.src;
      }
    ];
    interactiveShellInit = lib.strings.concatStrings (
      lib.strings.intersperse "\n" (
        [
        ]
        ++ [
          (builtins.readFile ./config.fish)
        ]
      )
    );
  };
}
