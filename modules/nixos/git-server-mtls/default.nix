# modules/nixos/git-server/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.git-server;

  # Use lighttpd for git-http-backend (simpler than nginx+fcgiwrap)
  lighttpdConfig = pkgs.writeText "lighttpd-git.conf" ''
    server.modules = ( "mod_setenv", "mod_cgi", "mod_alias" )
    server.port = ${toString cfg.port}
    server.bind = "127.0.0.1"
    server.document-root = "${cfg.repoPath}"

    setenv.add-environment = (
      "GIT_PROJECT_ROOT" => "${cfg.repoPath}",
      "GIT_HTTP_EXPORT_ALL" => "",
      "REMOTE_USER" => "git-user"
    )

    cgi.assign = ( "" => "" )
    alias.url = ( "/" => "${pkgs.git}/libexec/git-core/git-http-backend/" )
  '';
in
{
  options.services.git-server = {
    enable = mkEnableOption "Git server with mTLS";

    domainName = mkOption {
      type = types.str;
    };

    port = mkOption {
      type = types.port;
      default = 8080;
    };

    repoPath = mkOption {
      type = types.path;
      default = "/tank/git";
    };

    client_tls_ca_cert_sops_key = mkOption {
      type = types.str;
      default = "git_server_ca_cert";
    };

    repos = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    # Caddy handles all TLS and proxying
    services.caddy.enable = true;
    services.caddy.virtualHosts."${cfg.domainName}" = {
      extraConfig = ''
        tls {
          client_auth {
            mode require_and_verify
            trust_pool file {
              pem_file ${config.sops.secrets.${cfg.client_tls_ca_cert_sops_key}.path}
            }
          }
        }

        reverse_proxy localhost:${toString cfg.port} {
          header_up X-Remote-User {tls_client_subject_cn}
          header_up X-Client-DN {tls_client_subject}

          transport http {
            read_timeout 300s
          }
        }
      '';
    };

    # Run git-http-backend with lighttpd
    systemd.services.git-http-backend = {
      description = "Git HTTP Backend";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.lighttpd}/bin/lighttpd -D -f ${lighttpdConfig}";
        User = "git";
        Group = "git";
        Restart = "always";
      };
    };

    # Create repos
    systemd.tmpfiles.rules = [
      "d ${cfg.repoPath} 0755 git git -"
    ]
    ++ (map (repo: "d ${cfg.repoPath}/${repo}.git 0755 git git -") cfg.repos);

    users.users.git = {
      isSystemUser = true;
      group = "git";
    };
    users.groups.git = { };

    sops.secrets.${cfg.client_tls_ca_cert_sops_key} = {
      owner = "caddy";
      group = "caddy";
    };
  };
}
