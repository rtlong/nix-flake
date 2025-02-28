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
, # The system architecture for this host (eg. `x86_64-linux`).
  target
, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format
, # A normalized name for the system target (eg. `iso`).
  virtual
, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems
, # An attribute map of your defined hosts.

  # All other arguments come from the system system.
  config
, ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  config = {
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

    ## Servies 

    # Enable CUPS to print documents.
    services.printing.enable = true;

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    services.k3s = {
      enable = true;
      extraFlags = [ "--tls-san=optiplex,optiplex.liberty.rtlong.com" ];
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

    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    services.calibre-web = {
      enable = true;
      openFirewall = true;
      listen = {
        port = 8083;
        ip = "0.0.0.0";
      };
      options = {
        calibreLibrary = "/data/media/books";
      };
    };

    users.users.calibre-web = {
      extraGroups = [ "media" ];
    };

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

    #  services.static-web-server = {
    #    enable = true;
    #    listen = "[::]:8787";
    #    root = "/tmp/usb";
    #    configuration = {
    #      general = {
    #        directory-listing = true;
    #      };
    #    };
    #  };

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
      enable = true;
      openFirewall = true;
      user = "ryan";
      home = "/data/downloads";

      webHome = pkgs.flood-for-transmission;

      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-host-whitelist-enabled = false;
      };
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      hfsprogs
      zfs
      zfstools

      maestral # FOSS Dropbox.com client
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
