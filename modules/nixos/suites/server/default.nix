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

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "ryan@rtlong.com";
        dnsProvider = "route53";
        dnsPropagationCheck = false;
        credentialFiles = {
          AWS_CONFIG_FILE = config.sops.secrets.aws_credentials.path;
        };
        environmentFile = pkgs.writeText "lego-config" ''
          # do not follow CNAME on the _acme-challenge record, since I like to use wildcards pointing to this server
          LEGO_DISABLE_CNAME_SUPPORT=true
          LEGO_DEBUG_CLIENT_VERBOSE_ERROR=true
          LEGO_DEBUG_ACME_HTTP_CLIENT=true
        '';
      };
    };

    services.caddy = {
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/rtlong/caddy-route53@v0.0.0-20250913055854-44d25892d70a" ];
        hash = "sha256-CSJxg6Zu++CNSBJpxh38MFfjjDjWQp0/Xk8slSXDvSY=";
      };

      globalConfig = ''
        acme_dns route53 {
            max_retries 10
            aws_profile "default"
            wait_for_propagation true
            max_wait_dur 5m
        }
      '';
    };

  };
}
