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
    ${namespace} = {
      # nb: only one of these "dynamic attributes" can exist in this attrset
      suites.server.enable = true;

      smart-monitoring = {
        enable = true;
        devices = [
          { device = "/dev/sda"; }
          { device = "/dev/nvme0"; }
        ];
      };
    };

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

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    services.kubo = {
      # IPFS
      enable = true;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraSetFlags = [ ];
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

    security.acme = {
      certs = {
        "webdav.optiplex.tailnet.rtlong.com" = {
          group = "users";
          # acmeRoot = null; # use DNS-01 validation
        };
      };
    };

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
