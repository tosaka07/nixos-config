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
  # Host-specific configuration only
  system.stateVersion = 6;
  networking.hostName = hostname;
  system.primaryUser = username;

  # SSH configuration for this specific host
  home-manager.users.${username} = {
    programs.ssh.matchBlocks = {
      "*" = {
        extraOptions = {
          IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
        };
      };
    };
  };
}