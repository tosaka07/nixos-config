{
  programs.worktrunk = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/workspace/worktree/{{ repo }}/{{ branch | sanitize }}"
  '';
}
