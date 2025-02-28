{ config
, pkgs
, lib
, namespace
, ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.fonts;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/system/fonts/default.nix") ];

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        # Add any Linux-specific font packages here
      ] ++ cfg.fonts;
      # enableDefaultPackages = true;
    };
  };
}
