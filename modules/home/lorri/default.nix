{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:

let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.lorri;
in
{
  options.${namespace}.lorri = {

    # Enable lorri to manage running nix for development environments, in the background, keeping direnv's hooks very fast and non-blocking
    enable = mkBoolOpt true "Whether or not to enable lorri to manage running nix for development environments, in the background, keeping direnv's hooks very fast and non-blocking.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lorri ];

    launchd.agents = {
      "lorri" = {
        enable = true;
        config = {
          EnvironmentVariables = { };
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/var/tmp/lorri.log";
          StandardErrorPath = "/var/tmp/lorri.log";
          ProgramArguments = [
            "${pkgs.lorri}/bin/lorri"
            "daemon"
          ];
        };
      };
    };
  };
}
