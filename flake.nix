{
  description = "Nix configurations for TOSAKA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # homebrew 自体を Nix で管理するためのモジュール
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    laishulu-homebrew-homebrew = {
      url = "github:laishulu/homebrew-homebrew";
      flake = false;
    };

    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      laishulu-homebrew-homebrew,
      claude-code-overlay,
      ...
    }:
    let
      mkDarwinSystem = import ./modules/shared/mkDarwinSystem.nix {
        inherit
          nix-darwin
          home-manager
          nix-homebrew
          homebrew-core
          homebrew-cask
          laishulu-homebrew-homebrew
          claude-code-overlay
          ;
      };
    in
    {
      darwinConfigurations = {
        "CA-20033730" = mkDarwinSystem {
          hostname = "CA-20033730";
          username = "y41153";
          system = "aarch64-darwin";
        };
      };
    };
}
