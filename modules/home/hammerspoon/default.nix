{
  config,
  lib,
  namespace,
  ...
}:

let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt my-types;

  cfg = config.${namespace}.hammerspoon;
in
{
  options.${namespace}.hammerspoon = {
    enable = mkBoolOpt false "Whether or not to enable hammerspoon.";
    appLauncherBinds = mkOption {
      type = types.attrsOf my-types.binding;
      default = { };
      description = "Mapping of keys to application bindings.";
    };
  };

  config = mkIf cfg.enable {
    home.file.".hammerspoon/app-launch-binds.json".text = builtins.toJSON cfg.appLauncherBinds;
  };
}
