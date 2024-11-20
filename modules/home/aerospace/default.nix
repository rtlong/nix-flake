{ config, namespace, pkgs, lib, ... }:

let
  settingsFormat = pkgs.formats.toml { };

  defaultSettings = {
    start-at-login = true;

    enable-normalization-flatten-containers = false;
    enable-normalization-opposite-orientation-for-nested-containers = false;

    default-root-container-layout = "tiles";
    default-root-container-orientation = "auto";

    gaps = {
      inner = {
        horizontal = 10;
        vertical = 10;
      };

      outer = {
        left = 10;
        bottom = 10;
        top = 10;
        right = 10;
      };
    };

    key-mapping = {
      preset = "qwerty";
    };

    mode.main.binding =
      let
        meh = "ctrl-alt-shift";
      in
      {
        "${meh}-h" = "move left";
        "${meh}-j" = "move down";
        "${meh}-k" = "move up";
        "${meh}-l" = "move right";

        "${meh}-w" = "move-node-to-monitor --wrap-around left";
        "${meh}-e" = "move-node-to-monitor --wrap-around right";

        "${meh}-f" = "fullscreen";

        "${meh}-t" = "layout floating tiling";
      };
  };

  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.aerospace;
in
{
  options.${namespace}.aerospace = {
    enable = mkBoolOpt false "Enable aerospace WM";
    config = mkOption {
      type = types.attrsOf types.any;
      default = defaultSettings;
      description = "Settings for aerospace to be written as the aerospace.toml file";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aerospace ];

    xdg.configFile."aerospace/aerospace.toml".source = settingsFormat.generate "aerospace.toml" cfg.config;

    home.activation.aeorspaceConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
      $VERBOSE_ECHO "Reloading configuration"
      $DRY_RUN_CMD ${pkgs.aerospace}/bin/aerospace reload-config
    '';
  };
}
