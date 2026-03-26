#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3

"""
octorus パッケージの更新スクリプト

Usage:
  nix-shell -p python3 --run "python overlays/octorus/update.py"
"""

import json
import subprocess
import sys
import urllib.request
from pathlib import Path

OWNER = "ushironoko"
REPO = "octorus"

PLATFORM_MAP = {
    "aarch64-darwin": "aarch64-apple-darwin",
    "x86_64-darwin": "x86_64-apple-darwin",
    "aarch64-linux": "aarch64-unknown-linux-gnu",
    "x86_64-linux": "x86_64-unknown-linux-gnu",
}


def get_latest_release(owner: str, repo: str) -> str:
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "nix-update-script"})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read())
        return data["tag_name"].lstrip("v")


def prefetch_url(url: str) -> str:
    result = subprocess.run(
        ["nix-prefetch-url", url],
        capture_output=True,
        text=True,
        check=True,
    )
    nix32_hash = result.stdout.strip()
    result = subprocess.run(
        ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", nix32_hash],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def main():
    script_dir = Path(__file__).parent
    hashes_file = script_dir / "hashes.json"

    with open(hashes_file) as f:
        hashes = json.load(f)

    current_version = hashes["version"]
    print(f"Current version: {current_version}")

    latest_version = get_latest_release(OWNER, REPO)
    print(f"Latest version: {latest_version}")

    if current_version == latest_version:
        print("Already up to date.")
        return 0

    print(f"Updating {current_version} -> {latest_version}")

    new_hashes = {}
    for nix_system, platform in PLATFORM_MAP.items():
        url = f"https://github.com/{OWNER}/{REPO}/releases/download/v{latest_version}/{REPO}-{latest_version}-{platform}.tar.gz"
        print(f"Fetching hash for {nix_system}...")
        new_hashes[nix_system] = prefetch_url(url)
        print(f"  {new_hashes[nix_system]}")

    hashes["version"] = latest_version
    hashes["hashes"] = new_hashes

    with open(hashes_file, "w") as f:
        json.dump(hashes, f, indent=2)
        f.write("\n")

    print(f"Updated hashes.json to version {latest_version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
