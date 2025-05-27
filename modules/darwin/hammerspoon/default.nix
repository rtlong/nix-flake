{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    ;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.hammerspoon;
in
{
  options.${namespace}.hammerspoon = {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      casks = [
        "hammerspoon"
      ];
    };
  };
}
