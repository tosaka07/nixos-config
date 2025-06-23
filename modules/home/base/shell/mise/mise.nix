{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.mise = {
    enable = true;
    globalConfig = {
      env = {
        CLAUDE_CODE_USE_VERTEX = 1;
        CLOUD_ML_REGION = "us-east5";
        ANTHROPIC_VERTEX_PROJECT_ID = "inhouse-ai-tapple";
        ANTHROPIC_MODEL = "claude-opus-4@20250514";
        ANTHROPIC_SMALL_FAST_MODEL = "claude-sonnet-4@20250514";
      };
      tools = {
        flutter = "3.16.5-stable";
        go = "latest";
        node = "20.11.0";
        bun = "latest";
        python = "latest";
        bitwarden = "latest";
        uv = "latest";
        rust = "latest";
        "npm:opencommit" = "latest";
        "npm:@openai/codex" = "latest";
        "npm:@anthropic-ai/claude-code" = "latest";
        "npm:ccusage" = "latest";
        "pipx:posting" = "latest";
        "cargo:gitu" = "latest";
      };
      settings = {
        experimental = true;
        pipx.uvx = true;
        npm.bun = true;
      };
    };
  };
}
