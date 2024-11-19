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
  system
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
    # TODO: why can i not use `${namespace}  = {` here? I get an infinite recursion error
    skhd = {
      enable = true;
      appLaunchBinds = {
        A = "Activity Monitor";
        B = openBraveWithProfile "Default";
        C = openBraveWithProfile "Default";
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
        # O = "";
        P = "com.1password.1password";
        # Q = "";
        R = "Msty";
        S = "Slack";
        T = "iTerm2";
        U = "Perplexity";
        # V = "Discord";
        W = "Sonos";
        # X = "";
        Y = "Spotify";
        Z = "us.zoom.xos";
        # "," = "";
        # "." = "";
        # "-" = "";
      };
    };
  };

  home.packages = with pkgs; [
    inkscape-with-extensions

    pgadmin4-desktopmode

    vlc-bin-universal
    tailscale

    duckdb
  ];

  home.stateVersion = "22.05";
}

