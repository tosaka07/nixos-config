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
        GOOGLE_CLOUD_PROJECT = "inhouse-ai-tapple";
        GOOGLE_CLOUD_LOCATION = "us-central1";
        GOOGLE_GENAI_USE_VERTEXAI = true;
        DISABLE_AUTOUPDATER = 1;
      };
      tools = {
        flutter = "3.16.5-stable";
        go = "latest";
        node = "22.17.0";
        bun = "latest";
        python = "latest";
        uv = "latest";
        rust = "latest";
        deno = "latest";
        # "npm:opencommit" = "latest";
        # "npm:@openai/codex" = "latest";
        # "npm:@anthropic-ai/claude-code" = "latest";
        # "npm:@google/gemini-cli" = "latest";
        # "npm:ccusage" = "latest";
        # "npm:ccmanager" = "latest";
        # "pipx:posting" = "latest";
        # "cargo:gitu" = "latest";
      };
      settings = {
        idiomatic_version_file_enable_tools = [ ];
        experimental = true;
        pipx.uvx = true;
        npm.bun = true;
      };
    };
  };
}
