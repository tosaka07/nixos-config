{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "archive-downloads";
      runtimeInputs = [ pkgs.zip ];
      text = builtins.readFile ./archive-downloads.sh;
    })
  ];
}
