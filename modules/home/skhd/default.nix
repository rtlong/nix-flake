{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib)
    mkIf
    mkForce
    mkOption
    types
    ;
  inherit (lib.strings)
    toLower
    hasInfix
    hasPrefix
    removePrefix
    ;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.${namespace}) mkBoolOpt join;

  cfg = config.${namespace}.skhd;

  skhdrc = join "\n" (
    lib.remove null (
      lib.lists.flatten [
        (mapAttrsToList (
          key: application:
          if (lib.isString application) then
            let
              command =
                if (hasPrefix ": " application) then
                  removePrefix ": " application
                else if (hasInfix " " application) then
                  ''open -a "${application}"''
                else
                  (if (hasInfix "." application) then "open -b ${application}" else "open -a ${application}");
            in
            "cmd + alt + shift + ctrl - ${toLower key} : ${command}"
          else
            null
        ) cfg.appLaunchBinds)

        cfg.extraConfig
      ]
    )
  );

  binding = types.str; # TODO: define this type more richly, add constructors to build them and annotate intention instead of this cryptic magic string
  mkBindingOpt =
    default:
    mkOption {
      type = types.nullOr binding;
      default = default;
      description = "The binding for this key.";
    };
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

    # attrset of keys to map (combined with the MEH key [ctrl+shift+option] + command) to launch/focus Mac applications;
    appLaunchBinds = {
      A = mkBindingOpt "Activity Monitor";
      B = mkBindingOpt "Brave Browser";
      C = mkBindingOpt "Brave Browser";
      D = mkBindingOpt "Dash";
      E = mkBindingOpt '': osascript -e 'tell application "Emacs" to activate' '';
      F = mkBindingOpt "Finder";
      G = mkBindingOpt "Messages";
      H = mkBindingOpt null;
      I = mkBindingOpt "Calendar";
      J = mkBindingOpt null;
      K = mkBindingOpt null;
      L = mkBindingOpt null;
      M = mkBindingOpt "Mail";
      N = mkBindingOpt "Notes";
      O = mkBindingOpt null;
      P = mkBindingOpt "com.1password.1password";
      Q = mkBindingOpt "System Settings";
      R = mkBindingOpt null;
      S = mkBindingOpt null;
      T = mkBindingOpt "iTerm2";
      U = mkBindingOpt null;
      V = mkBindingOpt "Visual Studio Code";
      W = mkBindingOpt null;
      X = mkBindingOpt null;
      Y = mkBindingOpt "Spotify";
      Z = mkBindingOpt "us.zoom.xos";
      "0x2C" = # aka "/"
        mkBindingOpt null;

      # Do not use these:
      # "0x2B" = null # , -- this is bound globally by MacOS
      # "0x2F" = null # . -- this is bound globally by MacOS `sysdiagnose`
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."skhd/skhdrc" = {
      text = skhdrc;
      onChange =
        let
          plist = "${config.home.homeDirectory}/Library/LaunchAgents/${config.launchd.agents.skhd.config.Label}.plist";
        in
        ''
          launchctl unload ${plist};
          launchctl load ${plist}
        '';
    };

    launchd.agents.skhd = {
      enable = true;
      config = {
        StandardOutPath = "/tmp/skhd.log";
        StandardErrorPath = "/tmp/skhd.log";
        ProgramArguments = [
          "${cfg.package}/bin/skhd"
          "-V"
        ];
        KeepAlive = mkForce true;
        # FIXME: this needs to chill out whenever it's failing due to lacking permissions. It agressively restarts and makes it actually difficult to grant permissions for the new binary. Also is there some way to make it provide a consistent path to MacOS for this purpose, instead of the hashed store path that is version dependent?
        ProcessType = "Interactive";
      };
    };
  };
}
