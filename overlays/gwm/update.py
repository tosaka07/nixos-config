#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 nix-prefetch-github

"""
gwm パッケージの更新スクリプト

Usage:
  nix-shell -p python3 nix-prefetch-github --run "python overlays/gwm/update.py"
"""

import json
import subprocess
import sys
import urllib.request
from pathlib import Path


def get_latest_release(owner: str, repo: str) -> str:
    """GitHub API から最新リリースのバージョンを取得"""
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "nix-update-script"})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read())
        return data["tag_name"].lstrip("v")


def prefetch_github(owner: str, repo: str, rev: str) -> str:
    """nix-prefetch-github でソースのハッシュを取得"""
    result = subprocess.run(
        ["nix-prefetch-github", owner, repo, "--rev", rev, "--json"],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(result.stdout)
    return data["hash"]


def main():
    script_dir = Path(__file__).parent
    hashes_file = script_dir / "hashes.json"

    # 現在のハッシュを読み込み
    with open(hashes_file) as f:
        hashes = json.load(f)

    current_version = hashes["version"]
    print(f"Current version: {current_version}")

    # 最新バージョンを取得
    latest_version = get_latest_release("tosaka07", "gwm")
    print(f"Latest version: {latest_version}")

    if current_version == latest_version:
        print("Already up to date.")
        return 0

    print(f"Updating {current_version} -> {latest_version}")

    # ソースのハッシュを取得
    print("Fetching source hash...")
    new_hash = prefetch_github("tosaka07", "gwm", f"v{latest_version}")
    print(f"Source hash: {new_hash}")

    # hashes.json を更新
    hashes["version"] = latest_version
    hashes["hash"] = new_hash
    # cargoHash は Rust のビルド時に計算が必要
    # 新バージョンでは cargoHash が変わる可能性があるため、
    # 一旦空文字を設定してビルドエラーから正しい値を取得する必要がある
    # ここでは既存の cargoHash を維持（手動更新が必要な場合あり）

    with open(hashes_file, "w") as f:
        json.dump(hashes, f, indent=2)
        f.write("\n")

    print(f"Updated hashes.json to version {latest_version}")
    print("Note: cargoHash may need manual update if Cargo dependencies changed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
