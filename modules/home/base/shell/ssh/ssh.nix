{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    
    # Common SSH configuration for all systems
    includes = [
      "~/.orbstack/ssh/config"
    ];
    
    # Additional matchBlocks can be added by OS-specific modules
  };
}