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
        exec aws-vault exec opencounter -- aws rds generate-db-auth-token --hostname "$1" --port "$2" --user "$3"
      '';
    }
  );

  openBraveWithProfile =
    profile:
    let
      applescriptFile = pkgs.writeScript "open-brave-with-profile-${profile}.scpt" ''
        tell application "Brave Browser" to activate
        delay 0.2
        tell application "System Events"
            tell process "Brave Browser"
                click menu item "${profile}" of menu "Profiles" of menu bar 1
            end tell
        end tell
      '';
    in
    ": osascript ${applescriptFile}";
in
{

  rtlong = {
    spotify.enable = true;
    emacs.enable = true;

    skhd = {
      enable = true;
      appLaunchBinds = {
        A = "Activity Monitor";
        B = openBraveWithProfile "Personal";
        C = openBraveWithProfile "Work";
        D = "Dash";
        E = ": emacs-activate";
        F = "Finder";
        # G = "Messages";
        # H = "Home Assistant";
        I = '': osascript -e 'tell application "BusyCal" to activate' ''; # When launched using `open` BusyCal always prompts for some settings reset... IDK
        J = "com.culturedcode.ThingsMac";
        K = "Yubico Authenticator";
        L = "pgAdmin 4";
        M = "Mail";
        N = "Notes";
        O = "com.microsoft.Outlook";
        P = "com.1password.1password";
        Q = "System Settings";
        R = "LM Studio";
        S = "Slack";
        T = "Ghostty";
        U = "Perplexity";
        V = "Visual Studio Code";
        # W = "";
        # X = "";
        Y = "Spotify";
        Z = "us.zoom.xos";
        # "0x2B" = '': osascript -e 'tell application "System Settings" to activate' ''; # , -- this is bound globally by `tailspin`
        # "0x2F" = ""; # . -- this is bound globally by MacOS `sysdiagnose`
        # "0x2C" = ""; # /
      };
    };
  };

  home.shellAliases =
    {
      tf = "terraform";
      dc = "docker compose";
      with-creds = "op run -- aws-vault exec opencounter --";
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
        ]
    ));

  home.packages = with pkgs; [
    awscli
    aws-vault-wrapper
    derive-password
    echo-exec
    pgadmin-rds-password-helper
    github-cli
    # lastpass-cli
    lnav
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
