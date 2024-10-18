# FIXME: PR this back info nix-darwin
# TODO: migrate this to Snowfall package or something?
{ domains }:
{ config, lib, pkgs, ... }:

with lib;
let
  mapA = f: attrs: with builtins; attrValues (mapAttrs f attrs);
  package = pkgs.dnsmasq;
  bind = "127.0.0.1";
  port = 53;
  args = [
    "--listen-address=${bind}"
    "--port=${toString port}"
    "--no-daemon"
  ] ++ (map (domain: "--address=/${domain}/127.0.0.1") domains);
in
{
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

  environment.etc = builtins.listToAttrs (builtins.map
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
    domains);
}

