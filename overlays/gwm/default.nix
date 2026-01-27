{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:
let
  hashes = lib.importJSON ./hashes.json;
in
rustPlatform.buildRustPackage rec {
  pname = "gwm";
  inherit (hashes) version;

  src = fetchFromGitHub {
    owner = "tosaka07";
    repo = "gwm";
    rev = "v${version}";
    hash = hashes.hash;
  };

  cargoHash = hashes.cargoHash;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # テストは git リポジトリが必要なためサンドボックス環境ではスキップ
  doCheck = false;

  meta = with lib; {
    description = "Git Worktree Manager - A TUI application for managing git worktrees";
    homepage = "https://github.com/tosaka07/gwm";
    license = licenses.mit;
    mainProgram = "gwm";
  };
}
