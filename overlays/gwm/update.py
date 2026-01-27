#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 nix-prefetch-github

"""
gwm パッケージの更新スクリプト

Usage:
  nix-shell -p python3 nix-prefetch-github --run "python overlays/gwm/update.py"
"""

import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

# ビルドエラーから正しいハッシュを抽出するための正規表現
HASH_PATTERN = re.compile(r"got:\s+(sha256-[A-Za-z0-9+/]+=*)")
# ダミーハッシュ（ビルドを意図的に失敗させるため）
FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


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


def get_cargo_hash(flake_dir: Path, attr: str, hashes_file: Path, hashes: dict) -> str:
    """ビルドエラーから cargoHash を取得"""
    # 一時的にダミーハッシュを設定
    original_cargo_hash = hashes.get("cargoHash", "")
    hashes["cargoHash"] = FAKE_HASH

    with open(hashes_file, "w") as f:
        json.dump(hashes, f, indent=2)
        f.write("\n")

    print("Building with fake hash to get correct cargoHash...")

    # ビルドを試行（失敗することを期待）
    result = subprocess.run(
        [
            "nix",
            "build",
            f"{flake_dir}#{attr}",
            "--no-link",
            "--extra-experimental-features",
            "nix-command flakes",
        ],
        capture_output=True,
        text=True,
        cwd=flake_dir,
    )

    # stderr から正しいハッシュを抽出
    output = result.stderr + result.stdout
    match = HASH_PATTERN.search(output)

    if match:
        correct_hash = match.group(1)
        print(f"Found correct cargoHash: {correct_hash}")
        return correct_hash
    else:
        # ハッシュが見つからない場合は元の値に戻す
        print("Warning: Could not extract cargoHash from build output")
        print("Build output:")
        print(output[:2000])  # 最初の2000文字を表示
        return original_cargo_hash


def main():
    script_dir = Path(__file__).parent
    hashes_file = script_dir / "hashes.json"
    flake_dir = script_dir.parent.parent  # リポジトリルート

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

    # hashes.json を更新（cargoHash はまだ古い値）
    hashes["version"] = latest_version
    hashes["hash"] = new_hash

    # cargoHash を自動取得
    print("Fetching cargoHash...")
    new_cargo_hash = get_cargo_hash(flake_dir, "gwm", hashes_file, hashes)

    # 最終的な hashes.json を書き込み
    hashes["cargoHash"] = new_cargo_hash

    with open(hashes_file, "w") as f:
        json.dump(hashes, f, indent=2)
        f.write("\n")

    print(f"Updated hashes.json to version {latest_version}")
    print(f"  hash: {new_hash}")
    print(f"  cargoHash: {new_cargo_hash}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
