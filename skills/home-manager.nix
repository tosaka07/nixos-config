{ ... }:
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = ./src;
      filter.maxDepth = 1;
    };

    sources.mattpocock = {
      input = "mattpocock-skills";
      subdir = "skills";
      idPrefix = "mattpocock";
      filter.maxDepth = 2;
      # deprecated/in-progress/misc/personal は .claude-plugin/plugin.json の
      # 正式配布リストに含まれないため除外し、engineering/productivity のみ取り込む
      filter.nameRegex = "(engineering|productivity)/.*";
    };

    skills.enableAll = [ "local" "mattpocock" ];

    targets = {
      claude.enable = true;
      codex.enable = true;
    };

    excludePatterns = [
      "/.system"
      "/.claude"
    ];
  };
}
