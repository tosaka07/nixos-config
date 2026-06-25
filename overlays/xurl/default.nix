{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  hashes = lib.importJSON ./hashes.json;
  system = stdenvNoCC.hostPlatform.system;

  platformMap = {
    "aarch64-darwin" = "Darwin_arm64";
    "x86_64-darwin" = "Darwin_x86_64";
    "aarch64-linux" = "Linux_arm64";
    "x86_64-linux" = "Linux_x86_64";
  };

  platform = platformMap.${system} or (throw "Unsupported system: ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "xurl";
  inherit (hashes) version;

  src = fetchurl {
    url = "https://github.com/xdevplatform/xurl/releases/download/v${version}/xurl_${platform}.tar.gz";
    hash = hashes.hashes.${system} or (throw "No hash for system: ${system}");
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 xurl -t $out/bin
  '';

  meta = with lib; {
    description = "A curl-like CLI for the X (Twitter) API with OAuth support";
    homepage = "https://github.com/xdevplatform/xurl";
    license = licenses.asl20;
    mainProgram = "xurl";
    platforms = builtins.attrNames platformMap;
  };
}
