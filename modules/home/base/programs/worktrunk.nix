{
  programs.worktrunk = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/workspace/worktree/{{ repo }}/{{ branch | sanitize }}"

    [commit]
    stage = "all"

    [commit.generation]
    command = 'CLAUDECODE= MAX_THINKING_TOKENS=0 claude -p --no-session-persistence --model=haiku --tools=""'

    [merge]
    squash = true
    commit = true
    rebase = true
    remove = true

    [switch.picker]
    pager = "delta --paging=never"


    # gitignore されたファイル（.env, .direnv 等）を先にコピー
    # wta / --execute で起動するコマンドから即座に参照できるよう post-create で実行する
    [pre-start]
    copy = "wt step copy-ignored"

    # コピー対象から除外するパターン
    # サイズが大きく再生成も容易なため、各言語のビルド成果物・依存物はコピーしない
    [step.copy-ignored]
    exclude = [
      # Node.js / JS
      "node_modules/",
      ".next/",
      ".nuxt/",
      ".turbo/",
      ".cache/",
      ".parcel-cache/",
      ".svelte-kit/",
      "dist/",
      "build/",

      # Python / uv
      "__pycache__/",
      ".venv/",
      "venv/",
      ".pytest_cache/",
      ".mypy_cache/",
      ".ruff_cache/",
      ".tox/",
      "*.egg-info/",

      # Rust
      "target/",

      # Swift
      ".build/",
      "DerivedData/",
      "Pods/",
      ".swiftpm/",

      # JVM / Android
      ".gradle/",

      # Flutter / Dart
      ".dart_tool/",

      # Terraform
      ".terraform/",

      # Test coverage
      "coverage/",

      # Nix build outputs
      "result",
      "result-*",
    ]
  '';
}
