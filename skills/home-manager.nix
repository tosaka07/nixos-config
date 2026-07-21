{ ... }:
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = ./src;
      filter.maxDepth = 1;
    };

    # ~/.claude/skills/<skill-name>/SKILL.md のように直下 1 階層で
    # 認識される仕様のため、engineering/productivity をそれぞれ独立した
    # source にしてフラットな ID (idPrefix なし) で取り込む。
    # deprecated/in-progress/misc/personal は .claude-plugin/plugin.json の
    # 正式配布リストに含まれないため対象外。
    sources.mattpocock-engineering = {
      input = "mattpocock-skills";
      subdir = "skills/engineering";
      filter.maxDepth = 1;
    };

    sources.mattpocock-productivity = {
      input = "mattpocock-skills";
      subdir = "skills/productivity";
      filter.maxDepth = 1;
    };

    skills.enableAll = [ "local" "mattpocock-engineering" "mattpocock-productivity" ];

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
