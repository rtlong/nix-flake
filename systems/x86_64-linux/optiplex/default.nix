{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace,
  # The namespace used for your flake, defaulting to "internal" if not set.
  system,
  # The system architecture for this host (eg. `x86_64-linux`).
  target,
  # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format,
  # A normalized name for the system target (eg. `iso`).
  virtual,
  # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.

  # All other arguments come from the system system.
  config,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  config = {
    sops = {
      # This will add secrets.yml to the nix store
      # You can avoid this by adding a string to the full path instead, i.e.
      # defaultSopsFile = "/root/.sops/secrets/example.yaml";
      defaultSopsFile = ./secrets/default.yaml;
      defaultSopsFormat = "yaml";

      age = {
        # This will automatically import SSH keys as age keys
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
      # This is the actual specification of the secrets.
      secrets = {
        # example-key = {
        # sopsFile = ""; # override the defaultSopsFile, per secret
        # };
        "aws_credentials" = { };
      };
    };

    boot = {
      # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      kernelParams = [ "elevator=none" ]; # disable the disk scheduler to avoid issues with ZSH having only part of the disk
      supportedFilesystems = {
        zfs = lib.mkForce true;
      };

      # Use the systemd-boot EFI boot loader.
      loader = {
        systemd-boot.enable = true;

        efi.canTouchEfiVariables = true;
      };
      initrd = {
        kernelModules = [ "zfs" ];
      };
    };

    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";

    ## Networking
    networking.hostName = "optiplex"; # Define your hostname.
    networking.hostId = "267498f7"; # provide a unique 32-bit ID, primarily for use by ZFS. This one was derived from /etc/machine-id

    networking.networkmanager.enable = true;
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

    # Disable the firewall altogether.
    networking.firewall.enable = false;

    ## Users
    primaryUser = {
      extraGroups = [ "media" ];
    };

    users.groups.media = {
      name = "media";
    };
    users.groups.downloaders = {
      name = "downloaders";
    };

    ## Servies

    # Enable CUPS to print documents.
    services.printing = {
      enable = true;
      listenAddresses = [
        "*:631"
      ];
      drivers = with pkgs; [
        cups-dymo
      ];
      allowFrom = [ "all" ];
      defaultShared = true;
      browsing = true;
      browsed.enable = true;
      logLevel = "debug";
      extraConf = ''
        ServerAlias optiplex optiplex.liberty.rtlong.com optiplex.tailnet.rtlong.com
      '';
    };

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    services.ollama.enable = true;

    services.kubo = {
      # IPFS
      enable = true;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraSetFlags = [
        #"--accept-routes"
        "--exit-node-allow-lan-access"
        "--exit-node=100.89.129.123" # us-bos-wg-102.mullvad.ts.net
      ];
    };

    services.influxdb2 = {
      enable = true; # used by homeassistant (running on a standalone host)
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      ensureDatabases = [ "paperless" ];
      ensureUsers = [
        {
          name = "paperless";
          ensureDBOwnership = true;
        }
      ];
    };

    services.redis = {
      servers = {
        store = {
          enable = true;
          port = 6379;
        };
      };
    };

    services.syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
      user = "syncthing";
      group = "users";
    };

    users.users.syncthing = {
      extraGroups = [
        "media"
        "downloaders"
        "users"
      ];
    };

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          security = "user";
        };

        media = {
          "path" = "/data/media";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "ryan";
          "force group" = "users";
        };
        downloads = {
          "path" = "/data/downloads";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "ryan";
          "force group" = "users";
        };
        inbox = {
          "path" = "/data/inbox";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "ryan";
          "force group" = "users";
        };
      };
    };

    services.transmission = {
      enable = false;
      openFirewall = true;
      user = "ryan";
      home = "/data/downloads";

      webHome = pkgs.flood-for-transmission;

      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-host-whitelist-enabled = false;
        script-torrent-done-enabled = true;
        script-torrent-done-filename = ./bin/organize_downloads.sh;
      };
    };

    systemd.timers.organizeMedia = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };

    systemd.services.organizeMedia = {
      description = "Organize media into Jellyfin folders";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash ${./bin/organize_downloads.sh}";
        WorkingDirectory = "/";
      };
    };

    services.jellyfin = {
      enable = true;
      openFirewall = true;
      user = "jellyfin";
    };
    users.users.jellyfin.extraGroups = [
      "video"
      "render"
    ];
    # enable hardware acceleration in Jellyfin
    systemd.services.jellyfin = {
      environment = {
        LIBVA_DRIVER_NAME = "iHD";
      };
      serviceConfig = {
        SupplementaryGroups = [ "render" ];
        DevicePolicy = "auto";
        DeviceAllow = [ "/dev/dri/renderD128" ];
      };
    };
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ]; # or intel-vaapi-driver if iHD still fails
    };

    services.k3s = {
      enable = true;
      extraFlags = [
        "--tls-san=optiplex,optiplex.liberty.rtlong.com,optiplex.tailnet.rtlong.com"
      ];
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "ryan@rtlong.com";
        dnsProvider = "route53";
        dnsPropagationCheck = false;
        credentialFiles = {
          AWS_CONFIG_FILE = config.sops.secrets.aws_credentials.path;
        };
        environmentFile = pkgs.writeText "lego-config" ''
          # do not follow CNAME on the _acme-challenge record, since *.optiplex.tailnet.rtlong.com resolves all subdomains
          LEGO_DISABLE_CNAME_SUPPORT=true
          LEGO_DEBUG_CLIENT_VERBOSE_ERROR=true
          LEGO_DEBUG_ACME_HTTP_CLIENT=true
        '';
      };

      certs = {
        "webdav.optiplex.tailnet.rtlong.com" = {
          group = "users";
          # acmeRoot = null; # use DNS-01 validation
        };
      };
    };

    # systemd.units."secrets-test.service" = {
    #   text = ''
    #     [Service]
    #     Environment="AWS_CONFIG_FILE=%d/AWS_CONFIG_FILE"
    #     LoadCredential=AWS_CONFIG_FILE:/run/secrets/aws_credentials
    #     ExecStartPre=${pkgs.busybox}/bin/env
    #     ExecStartPre=/run/current-system/sw/bin/cat $AWS_CONFIG_FILE
    #     ExecStart=${pkgs.awscli}/bin/aws --debug sts get-caller-identity
    #   '';
    # };

    # security.pam.services.webdav = { };
    services.webdav = {
      enable = true;
      user = "ryan";
      group = "users";

      # http://optiplex.tailnet.rtlong.com:6050/org/index.org
      settings = {
        address = "0.0.0.0";
        port = 6050;
        tls = true;
        cert = "/var/lib/acme/webdav.optiplex.tailnet.rtlong.com/full.pem";
        key = "/var/lib/acme/webdav.optiplex.tailnet.rtlong.com/key.pem";
        directory = "/data/public";
        debug = true;
        modify = true;
        auth = true;
        users = [
          {
            username = "org-mobile";
            password = "{bcrypt}$2a$10$ETEOrBlS8knRUBPXrjUyyeEkZH7VSIgrcjO6zm4WOlDtAq.4rezki";
            directory = "/data/documents";
            permissions = "none";
            rules = [
              {
                path = "/org";
                permissions = "CRUD";
              }
              {
                path = "/org-roam";
                permissions = "CRUD";
              }
            ];
          }
        ];
      };
    };

    ## Containers
    # Enable Podman in configuration.nix
    virtualisation.podman = {
      enable = true;
      # Create the default bridge network for podman
      defaultNetwork.settings.dns_enabled = true;
    };

    # Optionally, create a Docker compatibility alias
    programs.zsh.shellAliases = {
      docker = "podman";
    };

    ${namespace}.smart-monitoring = {
      enable = true;
      devices = [
        { device = "/dev/sda"; }
        { device = "/dev/nvme0"; }
      ];
    };

    # TODO: set up paperless via Kubernetes instead
    # services.paperless = {
    #   enable = false;
    #   consumptionDirIsPublic = true;
    #   address = "paperless.lab.rtlong.com";
    #   passwordFile = "/etc/paperless-admin-pass";
    #   settings = {
    #     PAPERLESS_DBENGINE = "postgres";
    #     PAPERLESS_DBHOST = "localhost";
    #     PAPERLESS_CONSUMPTION_DIR = "/data/media/documents/inbox";
    #     PAPERLESS_CONSUMER_RECURSIVE = true;
    #     PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
    #     PAPERLESS_CONSUMER_IGNORE_PATTERN = [
    #       ".DS_STORE/*"
    #       "desktop.ini"
    #     ];
    #     PAPERLESS_OCR_LANGUAGE = "eng";
    #     PAPERLESS_OCR_USER_ARGS = {
    #       optimize = 1;
    #       pdfa_image_compression = "lossless";
    #     };
    #     PAPERLESS_TIME_ZONE = "America/New_York";
    #   };
    # };

    # TODO: set up calibre-web via Kubernetes instead; maybe alternative software exists for managing books/audiobooks like this?
    # services.calibre-web = {
    #   enable = false;
    #   openFirewall = true;
    #   listen = {
    #     port = 8083;
    #     ip = "0.0.0.0";
    #   };
    #   options = {
    #     calibreLibrary = "/data/media/books";
    #   };
    # };
    # users.users.calibre-web = {
    #   extraGroups = [ "media" ];
    # };

    # TODO: set up KanIDM (via Kubernetes? maybe)
    # KanIDM is a self-hosted identity and access management solution.
    # services.kanidm = {
    #   clientSettings = { };
    #   serverSettings = { };
    #   provision = {
    #     systems = {
    #       oauth2 = {
    #         (name) = { };
    #       };
    #     };
    #     persons = { };
    #     groups = { };
    #     adminPasswordFile = "/etc/kanidm/admin_password";
    #   };
    #   unixSettings = { };
    #   enableServer = true;
    #   enableClient = true;
    #   enablePAM = true;
    # };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      hfsprogs
      zfs
      zfstools
      mlocate

      # for Jellyfin HW acceleration:
      jellyfin-ffmpeg
      vaapiIntel
      intel-media-driver
      libva-utils
    ];

    ### END
    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
