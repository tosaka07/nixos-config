{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  # Common user system configuration for all platforms
  users.users.${username} = {
    home = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    shell = pkgs.zsh;
  };
}

