{ config, lib, pkgs, ... }:
with lib;
let
  mapA = f: attrs: with builtins; attrValues (mapAttrs f attrs);
  package = pkgs.dnsmasq;
  addresses = {
    test = "127.0.0.1"; # redirect all queries for *.test TLD to localhost
    localhost = "127.0.0.1"; # redirect all queries for *.localhost TLD to localhost
  };
  bind = "127.0.0.1";
  port = 53;
  args = [
    "--listen-address=${bind}"
    "--port=${toString port}"
    "--no-daemon"
  ] ++ (mapA (domain: addr: "--address=/${domain}/${addr}") addresses);
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
    (builtins.attrNames addresses));
}

