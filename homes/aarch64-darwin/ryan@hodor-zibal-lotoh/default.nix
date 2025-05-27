{
  pkgs,
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

in
{
  rtlong = {
    spotify.enable = true;
    emacs.enable = true;
    rancher-desktop.enable = true;

    app-launcher-hotkeys = {
      bindings = {
        H = {
          type = "appName";
          value = "Home Assistant";
        };
        K = {
          type = "appName";
          value = "Yubico Authenticator";
        };
        M = {
          type = "appName";
          value = "Spark Mail";
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

  home.packages = with pkgs; [
    aws-vault-wrapper
    # blender # BROKEN
    # cyberduck
    devenv
    duckdb
    ext4fuse
    inkscape-with-extensions
    keepassxc
    macfuse-stubs
    rtlong.open-webui
    pgadmin4-desktopmode
    tailscale
    vlc-bin-universal
    yubikey-manager
  ];

  services.syncthing = {
    enable = true;
    tray = {
      enable = false; # unsupported on macOS
    };

    # allow folders and devices configured manually to persist
    overrideDevices = false;
    overrideFolders = false;
  };

  home.shellAliases =
    {
      tf = "terraform";
      dc = "docker compose";
    }
    // (listToAttrs (
      map (cmd: {
        name = cmd;
        value = "with-creds ${cmd}";
      }) [ "terraform" ]
    ));

  programs.zsh.initContent = ''
    function with-creds() {
      if [[ -z $AWS_VAULT ]]; then
        op run -- aws-vault exec rtlong -- $@
      else
        command $@
      fi
    }
  '';

  home.stateVersion = "22.05";
}
