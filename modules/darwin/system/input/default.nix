{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.input;
in
{
  options.${namespace}.system.input = {
    enable = mkBoolOpt true "macOS input";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      system = {
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
          # swapLeftCommandAndLeftAlt = true;
        };

        defaults = {
          # trackpad settings
          trackpad = {
            # silent clicking = 0, default = 1
            ActuationStrength = 0;
            # enable tap to click
            Clicking = true;
            # firmness level, 0 = lightest, 2 = heaviest
            FirstClickThreshold = 1;
            # firmness level for force touch
            SecondClickThreshold = 1;
            # don't allow positional right click
            TrackpadRightClick = true;
            # three finger drag for space switching
            TrackpadThreeFingerDrag = true;
          };

          ".GlobalPreferences" = {
            "com.apple.mouse.scaling" = 1.0;
          };

          NSGlobalDomain = {
            AppleKeyboardUIMode = 3; # enable full keyboard control
            ApplePressAndHoldEnabled = false;

            KeyRepeat = 5;
            InitialKeyRepeat = 25;

            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
          };
        };
      };
    }
  ]);
}
