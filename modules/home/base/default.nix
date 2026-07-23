{
  config,
  lib,
  pkgs,
  system,
  llm-agents,
  ...
}:
{
  imports = [
    ./programs/archive-downloads.nix
    ./programs/fish/fish.nix
    ./programs/zellij/zellij.nix
    ./programs/atuin.nix
    ./programs/awake.nix
    ./programs/bat.nix
    ./programs/git.nix
    ./programs/gitui.nix
    ./programs/herdr.nix
    ./programs/mise.nix
    ./programs/ssh.nix
    ./programs/sheldon
    ./programs/tmux/tmux.nix
    ./programs/worktrunk.nix
    ./programs/zsh/default.nix
    ./programs/zsh/zeno.nix
  ];

  # Common CLI packages for all systems
  home.packages =
    with pkgs;
    [
      jq
      yq
      fzf
      fd
      ripgrep
      eza
      atuin
      starship
      zoxide
      neovim
      helix
      delta
      gh
      ghq
      git-lfs
      go-task
      nixfmt
      google-cloud-sdk
      gomi
      zellij
      glow
      ngrok
      difftastic
      hyperfine
      ghostscript
      _1password-cli
      ffmpeg
      devcontainer
      dasel
      yazi
      lazygit
      octorus
      xurl
      fresh-editor
      maestro
      azure-cli
      herdr
      beads

      # languages
      nixd
      nil
      cmake

      # fonts
      udev-gothic-nf
      plemoljp-nf
    ]
    ++ (with llm-agents.packages.${system}; [
      # llm-agents.nix から直接参照
      agent-browser
      amp
      ccstatusline
      ccusage
      claude-code
      codex
      copilot-cli
      cursor-agent
      # gemini-cli
      hunk
      opencode
    ]);
}
