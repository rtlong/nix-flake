{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

with lib;

let
  cfg = config.${namespace}.qbittorrent;
  UID = 888;
  GID = 888;
in
{
  options.${namespace}.qbittorrent = {
    enable = mkEnableOption (lib.mdDoc "qBittorrent headless");

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/qbittorrent";
      description = lib.mdDoc ''
        The directory where qBittorrent stores its data files.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "qbittorrent";
      description = lib.mdDoc ''
        User account under which qBittorrent runs.
      '';
    };

    userExtraGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = lib.mdDoc ''
        Extra group names to add to the user that qBittorrent runs as.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "qbittorrent";
      description = lib.mdDoc ''
        Group under which qBittorrent runs.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = lib.mdDoc ''
        qBittorrent web UI port.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Open services.qBittorrent.port to the outside network.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.qbittorrent-nox;
      defaultText = literalExpression "pkgs.qbittorrent-nox";
      description = lib.mdDoc ''
        The qbittorrent package to use.
      '';
    };

    networkInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        Network interface to bind to (e.g., "tailscale0").
        If null, qBittorrent will bind to all interfaces.
      '';
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = lib.mdDoc ''
        Additional qBittorrent settings to be merged into qBittorrent.conf.
        These will be converted to the INI format used by qBittorrent.
      '';
      example = literalExpression ''
        {
          Preferences = {
            "WebUI\\Port" = 8080;
            "Downloads\\SavePath" = "/var/lib/qbittorrent/downloads";
          };
        }
      '';
    };

    webUI = {
      passwordHash = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          PBKDF2 password hash for the WebUI admin user.
          If null, qBittorrent will generate a temporary password on startup.

          To generate a hash, set a password in the qBittorrent WebUI, then copy
          the value from WebUI\Password_PBKDF2 in qBittorrent.conf.
        '';
      };

      subnetWhitelist = mkOption {
        type = types.listOf types.str;
        default = [ "100.0.0.0/8" ];  # Tailscale network
        description = lib.mdDoc ''
          List of IP subnets that are allowed to bypass authentication.
        '';
      };
    };
  };

  config = mkIf cfg.enable (let
    # Generate qBittorrent.conf from settings
    settingsFormat = pkgs.formats.ini { };

    # Build WebUI preferences
    webUIPrefs = (optionalAttrs (cfg.webUI.passwordHash != null) {
      "WebUI\\Password_PBKDF2" = ''"@ByteArray(${cfg.webUI.passwordHash})"'';
    }) // {
      "WebUI\\Address" = "*";  # Listen on all interfaces
      "WebUI\\AuthSubnetWhitelist" = concatStringsSep ", " cfg.webUI.subnetWhitelist;
      "WebUI\\AuthSubnetWhitelistEnabled" = true;
      "WebUI\\HostHeaderValidation" = false;
      "WebUI\\LocalHostAuth" = false;
    };

    # Merge default settings with user settings and network interface config
    finalSettings = cfg.settings // {
      Preferences = (cfg.settings.Preferences or { }) //
        (optionalAttrs (cfg.networkInterface != null) {
          "Connection\\Interface" = cfg.networkInterface;
          "Connection\\InterfaceName" = cfg.networkInterface;
        }) // webUIPrefs;
    };

    configFile = settingsFormat.generate "qBittorrent.conf" finalSettings;
  in {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    systemd.services.qbittorrent = {
      # based on the plex.nix service module and
      # https://github.com/qbittorrent/qBittorrent/blob/master/dist/unix/systemd/qbittorrent-nox%40.service.in
      description = "qBittorrent-nox service";
      documentation = [ "man:qbittorrent-nox(1)" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;

        # Run the pre-start script with full permissions (the "!" prefix) so it
        # can create the data directory if necessary.
        ExecStartPre =
          let
            preStartScript = pkgs.writeScript "qbittorrent-run-prestart" ''
              #!${pkgs.bash}/bin/bash

              # Create data directory if it doesn't exist
              if ! test -d "$QBT_PROFILE"; then
                echo "Creating initial qBittorrent data directory in: $QBT_PROFILE"
                install -d -m 0755 -o "${cfg.user}" -g "${cfg.group}" "$QBT_PROFILE"
              fi

              # Create config directory if it doesn't exist
              config_dir="$QBT_PROFILE/qBittorrent/config"
              if ! test -d "$config_dir"; then
                echo "Creating qBittorrent config directory: $config_dir"
                install -d -m 0755 -o "${cfg.user}" -g "${cfg.group}" "$config_dir"
              fi

              # Copy generated config file
              config_file="$config_dir/qBittorrent.conf"
              if test -f "${configFile}"; then
                echo "Installing qBittorrent configuration from Nix store"
                ${pkgs.coreutils}/bin/cp "${configFile}" "$config_file"
                ${pkgs.coreutils}/bin/chown "${cfg.user}:${cfg.group}" "$config_file"
                ${pkgs.coreutils}/bin/chmod 644 "$config_file"
              fi
            '';
          in
          "!${preStartScript}";

        #ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
        ExecStart = "${cfg.package}/bin/qbittorrent-nox --confirm-legal-notice";
        # To prevent "Quit & shutdown daemon" from working; we want systemd to
        # manage it!
        #Restart = "on-success";
        #UMask = "0002";
        #LimitNOFILE = cfg.openFilesLimit;
      };

      environment = {
        QBT_PROFILE = cfg.dataDir;
        QBT_WEBUI_PORT = toString cfg.port;
      };
    };

    users.users = mkIf (cfg.user == "qbittorrent") {
      qbittorrent = {
        group = cfg.group;
        extraGroups = cfg.userExtraGroups;
        uid = UID;
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == "qbittorrent") {
      qbittorrent = {
        gid = GID;
      };
    };
  });
}
