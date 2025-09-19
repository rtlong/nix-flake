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
    mkDefault
    mkForce
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt mkBindingOpt my-types;

  cfg = config.${namespace}.app-launcher-hotkeys;

  defaultBindings = {
    A = {
      type = "appName";
      value = "Activity Monitor";
    };
    B = {
      type = "appName";
      value = "Brave Browser";
    };
    C = {
      type = "appName";
      value = "Brave Browser";
    };
    D = {
      type = "appName";
      value = "Dash";
    };
    E = {
      type = "nixApp";
      value = "Emacs";
    };
    F = {
      type = "appName";
      value = "Finder";
    };
    G = {
      type = "appName";
      value = "Messages";
    };
    # H = {};
    I = {
      type = "appName";
      value = "Calendar";
    };
    # J = {};
    # K = {};
    # L = {};
    M = {
      type = "appName";
      value = "Mail";
    };
    N = {
      type = "appName";
      value = "Notes";
    };
    # O = {};
    P = {
      type = "appBundleIdentifier";
      value = "com.1password.1password";
    };
    Q = {
      type = "appName";
      value = "System Settings";
    };
    # R = {};
    # S = {};
    T = {
      type = "appName";
      value = "iTerm2";
    };
    # U = {};
    V = {
      type = "nixApp";
      value = "Visual Studio Code";
    };
    # W = {};
    # X = {};
    Y = {
      type = "nixApp";
      value = "Spotify";
    };
    Z = {
      type = "appBundleIdentifier";
      value = "us.zoom.xos";
    };
  };

  # this set is the intersection of the keys on my layer 0 (which are not modifiers/meta themselves), and those which are actually available for mapping (not already consumed by the MacOS system)
  allowedKeys = [
    "A"
    "B"
    "C"
    "D"
    "E"
    "F"
    "G"
    "H"
    "I"
    "J"
    "K"
    "L"
    "M"
    "N"
    "O"
    "P"
    "Q"
    "R"
    "S"
    "T"
    "U"
    "V"
    "W"
    "X"
    "Y"
    "Z"
    "/"
    # TODO: can Bksp be mapped here?
    # NOTE: not allowed:
    # , -- this is bound globally by MacOS
    # . -- this is bound globally by MacOS `sysdiagnose`
  ];
in
{
  options.${namespace}.app-launcher-hotkeys = {
    enable = mkBoolOpt true "Whether or not to enable app-launcher-hotkeys.";

    bindings = mkOption {
      type = types.attrsOf (types.nullOr my-types.binding);
      default = { };
      apply = value: lib.filterAttrs (k: _: lib.elem k allowedKeys) value;
      description = "Map of MEH+Command keys to app launch bindings.";
    };
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      hammerspoon = {
        enable = mkForce true;
        appLauncherBinds = lib.recursiveUpdate defaultBindings cfg.bindings;
      };
    };
  };
}
