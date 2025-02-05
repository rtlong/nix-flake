{ config
, lib
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.input;
in
{
  options.${namespace}.system.input = {
    enable = mkBoolOpt true "linux input";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      system = {
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
          # swapLeftCommandAndLeftAlt = true;
        };

      };
    }
  ]);
}
