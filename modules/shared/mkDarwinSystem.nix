{
  nix-darwin,
  home-manager,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  laishulu-homebrew-homebrew,
  nikitabobko-homebrew-tap,
  typester-homebrew-yashiki,
  llm-agents,
  gwm,
  skills-catalog,
}:
{
  hostname,
  username,
  system,
}:
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = {
    inherit hostname username system llm-agents gwm;
  };
  modules = [
    # Common user system configuration
    ../users/base.nix

    # Common Darwin configuration
    ../darwin

    # Host-specific configuration
    (import ../hosts/${hostname} { inherit hostname username system; })

    # nix-homebrew configuration
    nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        enable = true;
        enableRosetta = false;
        user = username;
        taps = {
          "homebrew/homebrew-core" = homebrew-core;
          "homebrew/homebrew-cask" = homebrew-cask;
          "laishulu/homebrew-homebrew" = laishulu-homebrew-homebrew;
          "nikitabobko/homebrew-tap" = nikitabobko-homebrew-tap;
          "typester/homebrew-yashiki" = typester-homebrew-yashiki;
        };
        mutableTaps = false;
      };
    }

    # Home manager configuration
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = {
        inherit hostname username system llm-agents gwm;
      };

      home-manager.users.${username} = {
        imports = [
          (import ../users/${username} { inherit hostname username system; })
          skills-catalog.homeManagerModules.default
        ];
      };
    }
  ];
}
