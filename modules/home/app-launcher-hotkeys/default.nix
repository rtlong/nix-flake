{
  config,
  lib,
  namespace,
  ...
}:

let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib)
    mkIf
    mkOption
    mkForce
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt mkBindingOpt;

  cfg = config.${namespace}.app-launcher-hotkeys;
in
{
  options.${namespace}.app-launcher-hotkeys = {
    enable = mkBoolOpt true "Whether or not to enable app-launcher-hotkeys.";
    backend = mkOption {
      type = types.str;
      default = "skhd";
    };

    # default attrset of keys to map (combined with the MEH key [ctrl+shift+option] + command) to launch/focus Mac applications;
    appLaunchBinds = {
      A = mkBindingOpt "Activity Monitor";
      B = mkBindingOpt "Brave Browser";
      C = mkBindingOpt "Brave Browser";
      D = mkBindingOpt "Dash";
      E = mkBindingOpt "Emacs";
      F = mkBindingOpt "Finder";
      G = mkBindingOpt "Messages";
      H = mkBindingOpt null;
      I = mkBindingOpt "Calendar";
      J = mkBindingOpt null;
      K = mkBindingOpt null;
      L = mkBindingOpt null;
      M = mkBindingOpt "Mail";
      N = mkBindingOpt "Notes";
      O = mkBindingOpt null;
      P = mkBindingOpt "com.1password.1password";
      Q = mkBindingOpt "System Settings";
      R = mkBindingOpt null;
      S = mkBindingOpt null;
      T = mkBindingOpt "com.googlecode.iterm2";
      U = mkBindingOpt null;
      V = mkBindingOpt "Visual Studio Code";
      W = mkBindingOpt null;
      X = mkBindingOpt null;
      Y = mkBindingOpt "com.spotify.client";
      Z = mkBindingOpt "us.zoom.xos";
      "0x2C" = # aka "/"
        mkBindingOpt null;

      # Do not use these:
      # "0x2B" = null # , -- this is bound globally by MacOS
      # "0x2F" = null # . -- this is bound globally by MacOS `sysdiagnose`
    };
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      skhd = mkIf (cfg.backend == "skhd") {
        enable = mkForce true;
        appLaunchBinds = cfg.appLaunchBinds;
      };

      hammerspoon = mkIf (cfg.backend == "hammerspoon") {
        enable = mkForce true;
        appLaunchBinds = cfg.appLaunchBinds;
      };
    };
  };
}
