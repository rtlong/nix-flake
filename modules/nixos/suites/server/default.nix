{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.server;
in
{
  options.${namespace}.suites.server = {
    enable = mkBoolOpt true "Whether or not to enable server configuration.";
  };
  config = mkIf cfg.enable {
    services.netdata = {
      enable = true;

      package = pkgs.netdata.override {
        withCloudUi = true;
      };
      config = {
        global = {
          "memory mode" = "ram";
          "debug log" = "none";
          "access log" = "none";
          "error log" = "syslog";
        };
      };
    };
  };
}
