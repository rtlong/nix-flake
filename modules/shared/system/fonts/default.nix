{ config
, lib
, pkgs
, namespace
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.system.fonts;
in
{
  options.${namespace}.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts."; # FIXME: why do I need to provide true here to make this module take effect when i also have config.rtlong.system.fonts.enable = true; in modules/darwin/suites/common/default.nix ?
    fonts =
      with pkgs;
      mkOpt (listOf package) [
        # Desktop Fonts
        open-dyslexic

        # Emojis
        noto-fonts-color-emoji
        twemoji-color-font

        # Icons
        font-awesome

        # Nerd Fonts
        (
          nerdfonts #.override {
          # fonts = [
          #   "CascadiaCode"
          #   "Iosevka"
          #   "Monaspace"
          #   "NerdFontsSymbolsOnly"
          #   "OpenDyslexic"
          #   "Lilex"
          #   "FiraCode"
          # ];
          # }
        )
      ] "Custom font packages to install.";

    default = mkOpt types.str "MonaspiceNe Nerd Font" "Default font name";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };
  };
}
