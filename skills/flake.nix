{
  description = "Agent skills catalog for Claude Code";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  outputs =
    { self, agent-skills, mattpocock-skills, ... }:
    {
      homeManagerModules.default = {
        imports = [
          agent-skills.homeManagerModules.default
          ./home-manager.nix
        ];
      };
    };
}
