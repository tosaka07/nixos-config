{
  hostname,
  username,
  system,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (import ../../home/darwin { inherit hostname username system; })
  ];
}
