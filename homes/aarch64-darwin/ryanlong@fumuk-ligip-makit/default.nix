{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib
, # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs
, # You also have access to your flake's inputs.
  inputs
, # Additional metadata is provided by Snowfall Lib.
  namespace
, # The namespace used for your flake, defaulting to "internal" if not set.
  home
, # The home architecture for this host (eg. `x86_64-linux`).
  target
, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format
, # A normalized name for the home target (eg. `home`).
  virtual
, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host
, # The host name for this home.

  # All other arguments come from the home home.
  config
, ...
}:
let
  inherit (builtins) map listToAttrs;

  aws-vault-wrapper = (pkgs.writeShellApplication {
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
  });

  openBraveWithProfile = profile:
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
    user.human = "ryan";

    spotify.enable = true;

    skhd = {
      enable = true;
      appLaunchBinds = {
        A = "Activity Monitor";
        B = openBraveWithProfile "Personal";
        C = openBraveWithProfile "Work";
        D = "Dash";
        E = "Visual Studio Code";
        F = "Finder";
        G = "Messages";
        H = "Home Assistant";
        I = '': osascript -e 'tell application "BusyCal" to activate' ''; # When launched using `open` BusyCal always prompts for some settings reset... IDK
        J = "com.culturedcode.ThingsMac";
        K = "Yubico Authenticator";
        # L = "";
        M = "Spark Mail";
        N = "Notes";
        O = "com.microsoft.Outlook";
        P = "com.1password.1password";
        Q = "System Settings";
        # R = "";
        S = "Slack";
        T = "iTerm2";
        U = "Perplexity";
        # V = "";
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

  home.shellAliases = {
    tf = "terraform";
    dc = "docker compose";
    with-creds = "op run -- aws-vault exec opencounter --";
  } // (listToAttrs (map
    (cmd: {
      name = cmd;
      value = "with-creds ${cmd}";
    }) [ "rails" "sidekiq" "overmind" "terraform" ]));

  home.packages = with pkgs; [
    # Auth tools
    aws-vault-wrapper
    yubikey-manager
    lastpass-cli

    # Webservice CLIs
    awscli
    ssm-session-manager-plugin
    github-cli


    pgadmin4-desktopmode
  ];

  home.stateVersion = "22.05";
}
