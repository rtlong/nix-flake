{ config
, lib
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.${namespace}.nix;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/nix/default.nix") ];

  config = mkIf cfg.enable {
    nix = {
      # Options that aren't supported through nix-darwin
      extraOptions = ''
        # bail early on missing cache hits
        connect-timeout = 5
        keep-going = true
      '';

      gc = {
        interval = {
          Day = 7;
          Hour = 3;
        };

        user = config.${namespace}.user.name;
      };

      optimise = {
        interval = {
          Day = 7;
          Hour = 4;
        };

        user = config.${namespace}.user.name;
      };

      settings = {
        build-users-group = "nixbld";

        extra-sandbox-paths = [
          "/usr/lib"
          "/private/tmp"
          "/private/var/tmp"
          "/usr/bin/env"
        ];
      };
    };
  };
}
