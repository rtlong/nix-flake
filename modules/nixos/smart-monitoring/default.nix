{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  inherit (lib)
    mkIf
    mkForce
    mkOption
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.smart-monitoring;
in
{
  options.${namespace}.smart-monitoring = {
    enable = mkBoolOpt false "Whether or not to enable the S.M.A.R.T. monitoring for disk health.";
    devices = mkOption {
      type = types.listOf types.attrs;
      description = "List of devices to monitor.";
    };
    dashboard = {
      enable = mkBoolOpt true "Whether or not to enable the Scrutiny web UI for SMART drive monitoring";
    };
  };
  config = mkIf cfg.enable {
    services.smartd = {
      enable = mkForce true;
      devices = cfg.devices;
    };
    services.scrutiny = {
      enable = cfg.dashboard.enable;
      settings = {
        web.listen.port = 8223;
      };
    };

    environment.systemPackages = [
      pkgs.smartmontools
    ];
  };
}
