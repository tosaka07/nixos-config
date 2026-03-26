final: prev: {
  gwq = prev.callPackage ./gwq { };
  octorus = prev.callPackage ./octorus { };

  # Fix: https://github.com/NixOS/nixpkgs/pull/502769
  direnv = prev.direnv.overrideAttrs (old: {
    makeFlags = (old.makeFlags or [ ]) ++ [ "CGO_ENABLED=0" ];
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace GNUmakefile --replace-fail '-linkmode=external' ""
      '';
  });
}
