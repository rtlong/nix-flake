# FIXME: PR this back info nix-darwin
{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) types map listToAttrs mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.dnsmasq-dev-domains;

  # mapA = f: attrs: with builtins; attrValues (mapAttrs f attrs);
  package = pkgs.dnsmasq;
  bind = "127.0.0.1";
  port = 53;
  args = [
    "--listen-address=${bind}"
    "--port=${toString port}"
    "--no-daemon"
  ] ++ (map (domain: "--address=/${domain}/127.0.0.1") cfg.domains);
in
{
  options.${namespace}.dnsmasq-dev-domains = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    domains = mkOpt (listOf str) [ "localhost" ] "Which nix package to use.";
  };


  config = mkIf cfg.enable {
    environment.systemPackages = [ package ];

    launchd.daemons.dnsmasq = {
      # serviceConfig.Debug = true;
      serviceConfig.ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path ${package} &amp;&amp; exec ${package}/bin/dnsmasq ${toString args}"
      ];
      serviceConfig.StandardOutPath = /var/log/dnsmasq.log;
      serviceConfig.StandardErrorPath = /var/log/dnsmasq.log;
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = true;
    };

    environment.etc = listToAttrs (map
      (domain: {
        name = "resolver/${domain}";
        value = {
          enable = true;
          text = ''
            port ${toString port}
            nameserver ${bind}
          '';
        };
      })
      cfg.domains);
  };
}
