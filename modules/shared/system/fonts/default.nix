{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.system.fonts;

  defaultFontSet = with pkgs; [
    # Desktop Fonts
    open-dyslexic

    # Emojis
    noto-fonts-color-emoji
    twemoji-color-font

    # Icons
    font-awesome

    # Nerd Fonts
    nerd-fonts.fira-code
    nerd-fonts.inconsolata-go
    nerd-fonts.martian-mono
    nerd-fonts.ubuntu-mono
    nerd-fonts.droid-sans-mono
  ];
in
{
  options.${namespace}.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts."; # FIXME: why do I need to provide true here to make this module take effect when i also have config.rtlong.system.fonts.enable = true; in modules/darwin/suites/common/default.nix ?
    fonts = mkOpt (listOf package) defaultFontSet "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };
  };
}
