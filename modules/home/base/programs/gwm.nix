{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."gwm/config.toml".text = ''
    [worktree]
    basedir = ".git/wt"

    [naming]
    template = "wt-{branch}"
  '';
}
