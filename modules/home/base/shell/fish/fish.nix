{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Darwin-specific home configuration
  home.activation.configure-tide = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time=Yes --lean_prompt_height='Two lines' --prompt_connection=Solid --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Many icons' --transient=No"
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
