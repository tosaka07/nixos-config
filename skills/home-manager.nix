{ ... }:
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = ./src;
      filter.maxDepth = 1;
    };

    skills.enableAll = true;

    targets.claude.enable = true;

    excludePatterns = [
      "/.system"
      "/.claude"
    ];
  };
}
