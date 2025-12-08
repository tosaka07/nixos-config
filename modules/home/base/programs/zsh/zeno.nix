{
  config,
  lib,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };

  zenoConfig = {
    snippets = [
      # Git
      {
        name = "git status";
        keyword = "gs";
        snippet = "git status --short --branch";
      }
      {
        name = "git add";
        keyword = "ga";
        snippet = "git add";
      }
      {
        name = "git add all";
        keyword = "gaa";
        snippet = "git add --all";
      }
      {
        name = "git commit";
        keyword = "gc";
        snippet = "git commit -m '{{}}'";
      }
      {
        name = "git push";
        keyword = "gp";
        snippet = "git push";
      }
      {
        name = "git pull";
        keyword = "gl";
        snippet = "git pull";
      }
      {
        name = "git checkout";
        keyword = "gco";
        snippet = "git checkout";
      }
      {
        name = "git branch";
        keyword = "gb";
        snippet = "git branch";
      }
      {
        name = "git diff";
        keyword = "gd";
        snippet = "git diff";
      }
      {
        name = "git log oneline";
        keyword = "glo";
        snippet = "git log --oneline";
      }
    ];

    completions = [
      # Example completion
      # {
      #   name = "git branch";
      #   patterns = [ "^git checkout\\s" ];
      #   sourceCommand = "git branch -a --format='%(refname:short)'";
      #   options = {
      #     "--multi" = true;
      #     "--prompt" = "'Git Branch> '";
      #   };
      # }
    ];
  };
in
{
  xdg.configFile."zeno/config.yml".source = yamlFormat.generate "zeno-config.yml" zenoConfig;
}
