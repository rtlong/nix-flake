{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (builtins) map listToAttrs;

  aws-vault-wrapper = (
    pkgs.writeShellApplication {
      name = "aws-vault";
      runtimeEnv = {
        AWS_VAULT_BACKEND = "file";
        AWS_SESSION_TOKEN_TTL = "36h";
      };
      excludeShellChecks = [ "SC2209" ];
      text = ''
        exec env AWS_VAULT_FILE_PASSPHRASE="$(${pkgs._1password-cli}/bin/op --account my read op://qvutxi2zizeylilt23rflojdky/c5nz76at6k6vqx4cxhday5yg7u/password)" \
          "${pkgs.aws-vault}/bin/aws-vault" "$@"
      '';
    }
  );

  echo-exec = (
    pkgs.writeShellApplication {
      name = "echo-exec";
      text = ''
        echo "$@"  >&2
        exec "$@"
      '';
    }
  );

  derive-password = (
    pkgs.writeTextFile {
      name = "derive-password";
      executable = true;
      destination = "/bin/derive-password";
      text = ''
        #!${pkgs.ruby}/bin/ruby

        require 'openssl'
        require 'io/console'
        require 'base64'

        email = ARGV[0]
        index = ARGV[1]&.to_i || 0
        password = ENV.fetch('MASTER_PASSWORD') {
          `${pkgs._1password-cli}/bin/op --account my read "op://qvutxi2zizeylilt23rflojdky/5q2alfwlezaqtrmt7dj4w7mm24/password"`.strip
        }
        raise "Invalid Password" if password.length < 10

        key = OpenSSL::KDF.pbkdf2_hmac(password,
                                      salt: email,
                                      iterations: 1 + index,
                                      length: 30,
                                      hash: OpenSSL::Digest::SHA256.new)
        puts Base64.encode64(key)
      '';
    }
  );

  pgadmin-rds-password-helper = (
    pkgs.writeShellApplication {
      name = "pgadmin-rds-password-helper";
      runtimeInputs = with pkgs; [
        aws-vault-wrapper
        yubikey-manager
        awscli
      ];
      text = ''
        mkdir -p ~/.local/log
        exec 2> ~/.local/log/pdagmin-rds-password-helper.log
        exec aws rds generate-db-auth-token --hostname "$1" --port "$2" --user "$3"
      '';
    }
  );
in
{

  rtlong = {
    spotify.enable = true;
    emacs.enable = true;

    app-launcher-hotkeys = {
      bindings = {
        B = {
          type = "braveProfile";
          value = "Personal";
        };
        C = {
          type = "braveProfile";
          value = "Work";
        };
        G = {
          type = "appName";
          value = "Slack";
        };
        I = {
          type = "appName";
          value = "BusyCal";
        };
        K = {
          type = "appName";
          value = "Yubico Authenticator";
        };
        L = {
          type = "appName";
          value = "pgAdmin 4";
        };
        O = {
          type = "appBundleIdentifier";
          value = "com.microsoft.Outlook";
        };
        R = {
          type = "appName";
          value = "LM Studio";
        };
        U = {
          type = "appName";
          value = "Perplexity";
        };
      };

    };
  };

  home.shellAliases =
    {
      tf = "terraform";
      dc = "docker compose";
    }
    // (listToAttrs (
      map
        (cmd: {
          name = cmd;
          value = "with-creds ${cmd}";
        })
        [
          "rails"
          "sidekiq"
          "overmind"
          "terraform"
          "init-deployment"
          "aws"
        ]
    ));

  programs.zsh.initContent = ''
    function with-creds() {
      op run -- $@
    }
  '';

  home.packages = with pkgs; [
    aws-vault-wrapper
    awscli
    derive-password
    echo-exec
    github-cli
    lnav
    rtlong.open-webui
    pgadmin-rds-password-helper
    pgadmin4-desktopmode
    ssm-session-manager-plugin
    tailscale
    yubikey-manager
  ];

  services.syncthing = {
    enable = true;
    tray = {
      enable = false; # unsupported on macOS
    };
    overrideDevices = false;
    overrideFolders = false;
  };

  home.stateVersion = "22.05";
}
