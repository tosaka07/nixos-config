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
    ./programs/fish/fish.nix
    ./programs/zellij/zellij.nix
    ./programs/atuin.nix
    ./programs/bat.nix
    ./programs/git.nix
    ./programs/gitui.nix
    ./programs/mise.nix
    ./programs/ssh.nix
    ./programs/sheldon
    ./programs/tmux/tmux.nix
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
      delta
      gh
      ghq
      gwq
      gwm
      go-task
      nixfmt
      google-cloud-sdk
      gomi
      zellij
      glow
      ngrok
      yt-dlp
      difftastic
      hyperfine
      ghostscript
      _1password-cli
      ffmpeg
      devcontainer
      dasel
      yazi
      lazygit

      # languages
      nixd
      nil

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
      ccusage-codex
      claude-code
      codex
      copilot-cli
      cursor-agent
      # gemini-cli
      opencode
    ]);
}
