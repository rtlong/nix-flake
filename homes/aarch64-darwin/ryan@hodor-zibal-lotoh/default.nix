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

  openBraveWithProfile =
    profile:
    let
      applescriptFile = pkgs.writeScript "open-brave-with-profile-${profile}.scpt" ''
        tell application "Brave Browser" to activate
        delay 0.5
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
    rancher-desktop.enable = true;

    skhd = {
      enable = true;
      appLaunchBinds = {
        # B = openBraveWithProfile "Default";
        # C = openBraveWithProfile "Default";
        H = "Home Assistant";
        K = "Yubico Authenticator";
        M = "Spark Mail";
        R = "LM Studio";
        T = "Ghostty";
        U = "Perplexity";
      };
    };
  };

  home.packages = with pkgs; [
    aws-vault-wrapper
    # blender # BROKEN
    cyberduck
    devenv
    duckdb
    inkscape-with-extensions
    keepassxc
    pgadmin4-desktopmode
    tailscale
    vlc-bin-universal
    yubikey-manager

    macfuse-stubs
    ext4fuse
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
      with-creds = "op run -- aws-vault exec rtlong --";
      tf = "terraform";
      dc = "docker compose";
    }
    // (listToAttrs (
      map (cmd: {
        name = cmd;
        value = "with-creds ${cmd}";
      }) [ "terraform" ]
    ));

  home.stateVersion = "22.05";
}
