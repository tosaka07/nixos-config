{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."gwm/config.toml".text = ''
    [worktree]
    basedir = "~/workspace/worktrees"

    [naming]
    template = "{host}/{owner}/{repository}/{branch}"
  '';
}
