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
  inherit (lib.${namespace})
    mkBoolOpt
    join
    my-types
    mkBindingOpt
    ;

  cfg = config.${namespace}.skhd;

  openBraveWithProfile =
    profile:
    let
      applescriptFile = pkgs.writeScript "open-brave-with-profile-${profile}.scpt" ''
        tell application "Brave Browser" to activate
        delay 0.2
        tell application "System Events"
            tell process "Brave Browser"
                click menu item "${profile}" of menu "Profiles" of menu bar 1
            end tell
        end tell
      '';
    in
    ": osascript ${applescriptFile}";

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
                else if (hasInfix "." application) then
                  ''open -b "${application}"''
                else
                  ''open -a "${application}"'';
            in
            "cmd + alt + shift + ctrl - ${toLower key} : ${command}"
          else
            null
        ) cfg.appLaunchBinds)

        (mapAttrsToList (key: command: "${key} : ${command}") cfg.extraBinds)

        cfg.extraConfig
      ]
    )
  );
in
{
  options.${namespace}.skhd = {
    enable = mkBoolOpt false "Whether or not to enable skhd.";
    package = mkOption {
      type = types.package;
      default = pkgs.skhd;
      description = "This option specifies the skhd package to use.";
    };

    # attrset of keys to map (combined with the MEH key [ctrl+shift+option] + command) to launch/focus Mac applications;
    appLaunchBinds = {
      A = mkBindingOpt null;
      B = mkBindingOpt null;
      C = mkBindingOpt null;
      D = mkBindingOpt null;
      E = mkBindingOpt null;
      F = mkBindingOpt null;
      G = mkBindingOpt null;
      H = mkBindingOpt null;
      I = mkBindingOpt null;
      J = mkBindingOpt null;
      K = mkBindingOpt null;
      L = mkBindingOpt null;
      M = mkBindingOpt null;
      N = mkBindingOpt null;
      O = mkBindingOpt null;
      P = mkBindingOpt null;
      Q = mkBindingOpt null;
      R = mkBindingOpt null;
      S = mkBindingOpt null;
      T = mkBindingOpt null;
      U = mkBindingOpt null;
      V = mkBindingOpt null;
      W = mkBindingOpt null;
      X = mkBindingOpt null;
      Y = mkBindingOpt null;
      Z = mkBindingOpt null;
      "0x2C" = # aka "/"
        mkBindingOpt null;

      # Do not use these:
      # "0x2B" = null # , -- this is bound globally by MacOS
      # "0x2F" = null # . -- this is bound globally by MacOS `sysdiagnose`
    };

    extraBinds = mkOption {
      type = types.attrsOf my-types.binding;
      default = { };
      example = {
        "alt + shift - r" = "chunkc quit";
      };
      description = "Additional top-level binds";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''.load "partial_skhdrc"'';
      description = "Config to use for {file}`skhdrc`.";
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
