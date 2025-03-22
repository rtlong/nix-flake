{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.networking;
in
{
  options.${namespace}.system.networking = {
    enable = mkBoolOpt true "Whether or not to enable networking support";
  };

  config = mkIf cfg.enable {
    networking = {
      # dns = [
      #   "1.1.1.1"
      #   "8.8.8.8"
      # ];
    };
  };
}
