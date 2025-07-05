{
  config,
  lib,
  pkgs,
  ...
}:
let
  catppuccin-zellij = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "zellij";
    rev = "aaabdd0af9b4cf5a8c0d2195f8fdebdc8a015250";
    sha256 = "X00xZghPrHdLWZMUCxpjqqRRcdGrLIiW03YHDJmruPc=";
  };
in
{
  xdg.configFile."zellij/themes/catppuccin.kdl".source = "${catppuccin-zellij}/catppuccin.kdl";
  xdg.configFile."zellij/config.kdl".text = (builtins.readFile ./config.kdl);
}
