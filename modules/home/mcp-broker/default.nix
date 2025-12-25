{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  inherit (lib.types) str;

  cfg = config.${namespace}.mcp-broker;
in
{
  options.${namespace}.mcp-broker = {
    enable = mkBoolOpt false "Whether or not to enable MCP Broker service";
    projectPath = mkOpt str "${config.home.homeDirectory}/Code/github.com/rtlong/mcp_broker" "Path to the mcp_broker project directory";
  };

  config = mkIf cfg.enable {
    launchd.agents.mcp-broker = {
      enable = true;
      config = {
        WorkingDirectory = cfg.projectPath;
        EnvironmentVariables = {
          PATH = "${pkgs.lib.makeBinPath [ pkgs.erlang pkgs.elixir pkgs.openssl pkgs.coreutils ]}:/usr/bin:/bin";
        };
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/.local/state/mcp_broker/launchd-out.log";
        StandardErrorPath = "${config.home.homeDirectory}/.local/state/mcp_broker/launchd-error.log";
        ProgramArguments = [
          "${cfg.projectPath}/bin/start_broker"
        ];
      };
    };
  };
}
