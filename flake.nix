{
  description = "Nix configurations for TOSAKA";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

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

    nikitabobko-homebrew-tap = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gwm = {
      url = "github:tosaka07/gwm";
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
      nikitabobko-homebrew-tap,
      llm-agents,
      gwm,
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
          nikitabobko-homebrew-tap
          llm-agents
          gwm
          ;
      };
      # Overlay で定義したパッケージを packages 属性としてエクスポート
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "x86_64-darwin"
          ]
          (
            system:
            f (
              import nixpkgs {
                inherit system;
                overlays = [
                  (import ./overlays)
                  gwm.overlays.default
                ];
              }
            )
          );
    in
    {
      packages = forAllSystems (pkgs: {
        gwq = pkgs.gwq;
        gwm = pkgs.gwm;
      });

      darwinConfigurations = {
        "CA-20033730" = mkDarwinSystem {
          hostname = "CA-20033730";
          username = "y41153";
          system = "aarch64-darwin";
        };
      };
    };
}
