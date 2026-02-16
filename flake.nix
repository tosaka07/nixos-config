{
  description = "Nix configurations for TOSAKA";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
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

    typester-homebrew-yashiki = {
      url = "github:typester/homebrew-yashiki";
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

    skills-catalog = {
      url = "path:./skills";
      inputs.agent-skills.inputs.nixpkgs.follows = "nixpkgs";
      inputs.agent-skills.inputs.home-manager.follows = "home-manager";
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
      typester-homebrew-yashiki,
      llm-agents,
      gwm,
      skills-catalog,
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
          typester-homebrew-yashiki
          llm-agents
          gwm
          skills-catalog
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
