final: prev: {
  gwq = prev.callPackage ./gwq { };
  # TODO: Remove once nixpkgs-unstable includes NixOS/nixpkgs#534965.
  mise = prev.mise.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = "2026.6.13";
      src = prev.fetchFromGitHub {
        owner = "jdx";
        repo = "mise";
        tag = "v2026.6.13";
        hash = "sha256-/HE/2bHUz1gPpyLZnKZO5ZqT5oxOn+SZ0J4vyj67Ohs=";
      };
      cargoHash = "sha256-p7PCqwS0bI7kXvGYZm4bWpYhz1kkqILDCPGlEq32Cqo=";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src;
        hash = finalAttrs.cargoHash;
      };
      checkFlags = prev.lib.unique (
        (previousAttrs.checkFlags or [ ])
        ++ [
          "--skip=oci::layer::tests::preserve_metadata_dir_layer_keeps_special_permission_bits"
        ]
      );
    }
  );
  octorus = prev.callPackage ./octorus { };
  xurl = prev.callPackage ./xurl { };
}
