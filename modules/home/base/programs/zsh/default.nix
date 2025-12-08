{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    initContent = lib.strings.concatStrings (
      lib.strings.intersperse "\n" ([
        (builtins.readFile ./config.zsh)
      ])
    );
  };
}
