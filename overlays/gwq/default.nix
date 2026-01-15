{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
let
  hashes = lib.importJSON ./hashes.json;
in
buildGoModule rec {
  pname = "gwq";
  inherit (hashes) version;

  src = fetchFromGitHub {
    owner = "d-kuro";
    repo = "gwq";
    rev = "v${version}";
    hash = hashes.hash;
  };

  vendorHash = hashes.vendorHash;

  subPackages = [ "cmd/gwq" ];

  meta = with lib; {
    description = "Git worktree manager with fuzzy finder interface";
    homepage = "https://github.com/d-kuro/gwq";
    license = licenses.asl20;
    mainProgram = "gwq";
  };
}
