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


    # gitignore されたファイル（.env, node_modules, .direnv 等）を先にコピー
    # wta / --execute で起動するコマンドから即座に参照できるよう post-create で実行する
    [post-create]
    copy = "wt step copy-ignored"
  '';
}
