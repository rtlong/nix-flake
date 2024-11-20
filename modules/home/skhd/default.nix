{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib
, # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs
, # You also have access to your flake's inputs.
  inputs
, # Additional metadata is provided by Snowfall Lib.
  namespace
, # The namespace used for your flake, defaulting to "internal" if not set.
  system
, # The home architecture for this host (eg. `x86_64-linux`).
  target
, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format
, # A normalized name for the home target (eg. `home`).
  virtual
, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host
, # The host name for this home.

  # All other arguments come from the home home.
  config
, ...
}:
let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib) mkIf mkOption types;
  inherit (lib.strings) toLower hasInfix hasPrefix removePrefix;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.${namespace}) mkBoolOpt join;

  cfg = config.${namespace}.skhd;

  skhdrc = join "\n" (lib.lists.flatten
    [
      (mapAttrsToList

        (key: application:
          let
            command =
              if (hasPrefix ": " application)
              then removePrefix ": " application
              else
                if (hasInfix " " application)
                then ''open -a "${application}"''
                else
                  (if (hasInfix "." application)
                  then "open -b ${application}"
                  else "open -a ${application}");
          in
          "cmd + alt + shift + ctrl - ${toLower key} : ${command}")
        cfg.appLaunchBinds)

      cfg.extraConfig
    ]);
in
{
  options.${namespace}.skhd = {
    enable = mkBoolOpt false "Whether or not to enable skhd.";
    package = mkOption {
      type = types.package;
      default = pkgs.skhd;
      description = "This option specifies the skhd package to use.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "alt + shift - r   :   chunkc quit";
      description = "Config to use for {file}`skhdrc`.";
    };

    appLaunchBinds = mkOption {
      type = types.attrsOf types.str;
      default = {
        A = "Activity Monitor";
        F = "Finder";
        G = "Messages";
        I = "Calendar";
        M = "Mail";
        N = "Notes";
        P = "com.1password.1password";
        T = "iTerm2";
        Y = "Spotify";
      };
      description = "attrset of keys to map (combined with the MEH key [ctrl+shift+option] + command) to launch/focus Mac applications";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."skhd/skhdrc".text = skhdrc;

    launchd.agents.skhd = {
      enable = true;
      config = {
        StandardOutPath = "/tmp/skhd.log";
        StandardErrorPath = "/tmp/skhd.log";
        ProgramArguments = [ "${cfg.package}/bin/skhd" "-V" ];
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };
}
