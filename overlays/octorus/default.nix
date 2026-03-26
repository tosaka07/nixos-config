{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  hashes = lib.importJSON ./hashes.json;
  system = stdenvNoCC.hostPlatform.system;

  platformMap = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-linux" = "aarch64-unknown-linux-gnu";
    "x86_64-linux" = "x86_64-unknown-linux-gnu";
  };

  platform = platformMap.${system} or (throw "Unsupported system: ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "octorus";
  inherit (hashes) version;

  src = fetchurl {
    url = "https://github.com/ushironoko/octorus/releases/download/v${version}/octorus-${version}-${platform}.tar.gz";
    hash = hashes.hashes.${system} or (throw "No hash for system: ${system}");
  };

  sourceRoot = "octorus-${version}-${platform}";

  installPhase = ''
    install -Dm755 or -t $out/bin
  '';

  meta = with lib; {
    description = "TUI PR review tool for GitHub";
    homepage = "https://github.com/ushironoko/octorus";
    license = licenses.mit;
    mainProgram = "or";
    platforms = builtins.attrNames platformMap;
  };
}
