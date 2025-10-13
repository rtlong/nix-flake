# /etc/nixos/mouse-trap-monitor.nix
{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    types
    mkEnableOption
    ;
  inherit (lib.strings) floatToString;
  # inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.mouse-trap-checker;

  # Wrapper script to run the Elixir app
  runScript = pkgs.writeShellApplication {
    name = "run-mouse-monitor";
    runtimeInputs = with pkgs; [
      elixir
      imagemagick
    ];
    runtimeEnv = {
      MIX_HOME = "/var/lib/mouse-monitor/.mix";
      HEX_HOME = "/var/lib/mouse-monitor/.hex";
      LANG = "en_US.UTF-8";
    };
    text = ''
      # Load the HA token from SOPS (if using raw token value)
      if [ -f "${config.sops.secrets.${cfg.ha_token_secret_key}.path}" ]; then
        HA_TOKEN=$(cat "${config.sops.secrets.${cfg.ha_token_secret_key}.path}")
        export HA_TOKEN
      fi
      elixir --sname mouse-monitor --cookie chocolate-chip  ${./mouse_trap_checker.exs}
    '';
  };
in
{
  options.${namespace}.mouse-trap-checker = {
    enable = mkEnableOption "enable mouse-trap-checker";

    ha_url = mkOption {
      type = types.str;
    };

    ha_token_secret_key = mkOption {
      type = types.str;
      default = "homeassistant_token";
    };

    camera_ha_entity_id = mkOption {
      type = types.str;
    };

    image_url = mkOption {
      type = types.str;
    };
    difference_threshold = mkOption {
      type = types.float;
      default = 10000.0;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mouse-monitor = {
      description = "Mouse Trap Monitor (Elixir)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${runScript}/bin/run-mouse-monitor";
        Restart = "always";
        RestartSec = "30";

        # Run as dedicated user
        User = "mouse-monitor";
        Group = "applications";

        # Working directory
        WorkingDirectory = "/var/lib/mouse-monitor";

        # Security
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/mouse-monitor" ];
        NoNewPrivileges = true;

        # Environment
        Environment = [
          "MIX_ENV=prod"
          "HA_URL=${cfg.ha_url}"
          "CAMERA_ENTITY=${cfg.camera_ha_entity_id}"
          "CAMERA_URL=${cfg.image_url}"
          "DIFFERENCE_THRESHOLD=${floatToString cfg.difference_threshold}"
        ];

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "mouse-monitor";
      };

      preStart = ''
        # Ensure Mix/Hex are set up
        export MIX_HOME=/var/lib/mouse-monitor/.mix
        export HEX_HOME=/var/lib/mouse-monitor/.hex

        ${pkgs.elixir}/bin/mix local.hex --force --if-missing
        ${pkgs.elixir}/bin/mix local.rebar --force --if-missing
      '';

      unitConfig.After = [ "sops-nix.service" ];
    };

    # Create user
    users.users.mouse-monitor = {
      isSystemUser = true;
      group = "applications";
      home = "/var/lib/mouse-monitor";
      createHome = true;
    };

    sops.secrets.${cfg.ha_token_secret_key} = {
      owner = config.users.users.mouse-monitor.name;
    };

    # Required packages
    environment.systemPackages = [ runScript ];
  };
}
