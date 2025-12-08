{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.sheldon = {
    enable = true;
    settings = {
      shell = "zsh";
      plugins = {
        "zsh-async" = {
          github = "mafredri/zsh-async";
        };
        "zsh-autosuggestions" = {
          github = "zsh-users/zsh-autosuggestions";
        };
        "fast-syntax-highlighting" = {
          github = "zdharma-continuum/fast-syntax-highlighting";
        };
        "zsh-completions" = {
          github = "zsh-users/zsh-completions";
        };
        "zsh-dirnav" = {
          github = "Zile995/zsh-dirnav";
        };
        "fzf-tab" = {
          github = "Aloxaf/fzf-tab";
        };
        "zeno" = {
          github = "yuki-yano/zeno.zsh";
        };
        "pure" = {
          github = "sindresorhus/pure";
          use = [
            "async.zsh"
            "pure.zsh"
          ];
        };
      };
    };
    enableZshIntegration = false;
    enableFishIntegration = false;
    enableBashIntegration = false;
  };
}
