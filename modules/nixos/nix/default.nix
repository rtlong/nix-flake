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
        dates = "Mon *-*-* 03:00:00";
      };

      optimise = {
        dates = [ "Mon *-*-* 04:00:00" ];
      };

      settings = {
        build-users-group = "nixbld";

        extra-sandbox-paths = [
          "/usr/bin/env"
        ];
      };
    };

    programs.nix-index.enable = true;
    programs.nix-index.enableZshIntegration = true;
    programs.command-not-found.enable = false;

    security.sudo.extraRules = [
      # Allow execution of "nixos-rebuild switch" by user `nixbuild` without a password.
      {
        users = [
          "nixbuild"
          config.primaryUser.name
        ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

  };
}
