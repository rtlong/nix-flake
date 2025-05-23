{
  config,
  lib,
  namespace,
  ...
}:

let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkBindingOpt;

  cfg = config.${namespace}.hammerspoon;
in
{
  options.${namespace}.hammerspoon = {
    enable = mkBoolOpt false "Whether or not to enable hammerspoon.";

    appLaunchBinds = {
      A = mkBindingOpt null;
      B = mkBindingOpt null;
      C = mkBindingOpt null;
      D = mkBindingOpt null;
      E = mkBindingOpt null;
      F = mkBindingOpt null;
      G = mkBindingOpt null;
      H = mkBindingOpt null;
      I = mkBindingOpt null;
      J = mkBindingOpt null;
      K = mkBindingOpt null;
      L = mkBindingOpt null;
      M = mkBindingOpt null;
      N = mkBindingOpt null;
      O = mkBindingOpt null;
      P = mkBindingOpt null;
      Q = mkBindingOpt null;
      R = mkBindingOpt null;
      S = mkBindingOpt null;
      T = mkBindingOpt null;
      U = mkBindingOpt null;
      V = mkBindingOpt null;
      W = mkBindingOpt null;
      X = mkBindingOpt null;
      Y = mkBindingOpt null;
      Z = mkBindingOpt null;
      "0x2C" = # aka "/"
        mkBindingOpt null;

      # Do not use these:
      # "0x2B" = null # , -- this is bound globally by MacOS
      # "0x2F" = null # . -- this is bound globally by MacOS `sysdiagnose`
    };
  };

  config = mkIf cfg.enable {
    home.file.".hammerspoon/app-launch-binds.json".text = builtins.toJSON cfg.appLaunchBinds;
  };
}
