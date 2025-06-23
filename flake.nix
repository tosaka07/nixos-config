{
  description = "Nix configurations for TOSAKA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
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

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew のパッケージを直接取得してnixで管理するモジュール
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      brew-nix,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }:
    let
      mkDarwinSystem = import ./modules/shared/mkDarwinSystem.nix {
        inherit
          nix-darwin
          brew-nix
          home-manager
          nix-homebrew
          homebrew-core
          homebrew-cask
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
