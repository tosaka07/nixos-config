{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "tosaka07";
    userEmail = "tosakaup@gmail.com";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvcAZ9jZqsuhal3eUhcz3TCztfXaUfv5XqH+bmdZ2Dv";
      signByDefault = true;
    };

    aliases = {
      # add
      a = "add";
      chunkyadd = "add --patch";

      # snapshots
      snapshot = "!git stash save \"snapshot: $(date)\" && git stash apply \"stash@{0}\"";
      snapshots = "!git stash list --grep snapshot";

      # branches
      recent-branches = "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      b = "branch -v";

      # commit
      c = "commit -m";
      ca = "commit -am";
      ci = "commit";
      amend = "commit --amend";
      ammend = "commit --amend";

      # checkout
      co = "checkout";
      nb = "checkout -b";

      # cherry-pick
      cp = "cherry-pick -x";

      # diff
      d = "diff";
      dc = "diff --cached";
      last = "diff HEAD^";
      ds0 = "diff stash@{0}";
      ds1 = "diff stash@{1}";
      ds2 = "diff stash@{2}";

      # log
      l = "log --graph --date=short";
      changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
      short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
      simple = "log --pretty=format:\" * %s\"";
      shortnocolor = "log --pretty=format:\"%h %cr %cn %s\"";

      # pull/push
      pl = "pull";
      ps = "push";

      # rebase
      rc = "rebase --continue";
      rs = "rebase --skip";

      # remote
      r = "remote -v";

      # reset
      unstage = "reset HEAD";
      uncommit = "reset --soft HEAD^";
      filelog = "log -u";
      mt = "mergetool";

      # stash
      ss = "stash save";
      sl = "stash list";
      sa = "stash apply";
      sd = "stash drop";
      sp = "stash pop";

      # status
      s = "status";
      st = "status";
      stat = "status";

      # tag
      t = "tag -n";

      # list
      aliases = "!git config --get-regexp alias | sed 's/^alias.//g' | sed 's/ / = /1'";

      # svn helpers
      svnr = "svn rebase";
      svnd = "svn dcommit";
      svnl = "svn log --oneline --show-commit";

      # ローカルのみ残っている残りカスブランチを削除する
      nifuramu = "!f () { git checkout $1; git branch --merged|egrep -v '\\*|develop|main'|xargs git branch -d; git fetch --prune; };f";
    };

    extraConfig = {
      color = {
        ui = true;
        branch = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };
        diff = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red";
          new = "green";
        };
      };

      format = {
        pretty = "format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset";
      };

      mergetool = {
        prompt = false;
        mvimdiff = {
          cmd = "mvim -c 'Gdiff' $MERGED";
          keepbackup = false;
        };
      };

      merge = {
        summary = true;
        verbosity = 1;
        tool = "mvimdiff";
      };

      apply = {
        whitespace = "nowarn";
      };

      branch = {
        autosetupmerge = true;
      };

      push = {
        default = "current";
      };

      core = {
        autocrlf = false;
        editor = "vim";
        ignorecase = false;
        quotepath = false;
        pager = "delta";
      };

      advice = {
        statusHints = false;
      };

      diff = {
        mnemonicprefix = true;
        algorithm = "patience";
      };

      rerere = {
        enabled = true;
      };

      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };

      fetch = {
        prune = true;
      };

      ghq = {
        root = "~/workspace/sources";
      };

      filter = {
        lfs = {
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
          clean = "git-lfs clean -- %f";
        };
      };

      pager = {
        diff = "delta";
        log = "delta";
        reflog = "delta";
        show = "delta";
      };

      delta = {
        enable = true;
        options = {
          plus-style = "syntax #012800";
          minus-style = "syntax #340001";
          syntax-theme = "Visual Studio Dark+";
          navigate = true;
          line-numbers = true;
        };
      };

      interactive = {
        diffFilter = "delta --color-only";
      };

      include = {
        path = ".gitconfig.user";
      };
    };
  };
}
