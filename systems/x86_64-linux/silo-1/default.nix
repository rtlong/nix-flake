{
  lib,
  pkgs,
  # inputs,
  namespace,
  # system,
  # target,
  # format,
  # virtual,
  # systems,
  config,
  ...
}:
{
  imports = [
    ./disko.nix
  ];

  config = {
    ${namespace} = {
      suites.server.enable = true;

      # SMART monitoring
      smart-monitoring = {
        enable = true;
        devices = [
          { device = "dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB4263W100817P220J"; }
          { device = "dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251730044"; }
          { device = "dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB4263W101865P220J"; }
          { device = "dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251740100"; }
          { device = "dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB6866W100062P220J"; }
          { device = "dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251730134"; }
        ];
      };

      qbittorrent = {
        enable = false;
        port = 8056;
        userExtraGroups = [
          "media"
        ];
      };

      mouse-trap-checker = {
        enable = true;
        ha_url = "http://192.168.8.195:8123";
        # ha_token_secret = config.sops.homeassistant_token.path;
        camera_ha_entity_id = "camera.mousetrap_cam_camera";
        image_url = "http://192.168.8.237:8081";
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
        aws_credentials = {
          owner = "caddy";
          group = "caddy";
        };
        homeassistant_token = {
          group = "applications";

        };

      };
    };
    users.groups.applications = { };

    boot = {
      loader = {
        systemd-boot.enable = true;

        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = "/boot/efi";
      };
      initrd = {
        kernelModules = [ "zfs" ];
        availableKernelModules = [
          "xhci_pci"
          "nvme"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "sdhci_pci"
        ];
        systemd.enable = true;
      };
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
      supportedFilesystems = {
        zfs = lib.mkForce true;
      };
      # zfs.extraPools = [ "tank" ];
    };

    disko.enableConfig = true;

    fileSystems = {
      # NB: the /boot/efi mount of the ESP partition is configured in disko.nix
      "/" = {
        device = "tank/system/root"; # not encrypted for now to avoid complexity, planning to set up Tang later for headless reboots
        fsType = "zfs";
      };
      "/nix" = {
        device = "tank/nix"; # not encrypted for now to avoid complexity, planning to set up Tang later for headless reboots
        fsType = "zfs";
      };
      "/home" = {
        device = "tank/encrypted/system/home";
        fsType = "zfs";
      };
      "/var" = {
        device = "tank/encrypted/system/var";
        fsType = "zfs";
      };
      "/var/lib" = {
        device = "tank/encrypted/system/var/lib";
        fsType = "zfs";
      };
      "/var/log" = {
        device = "tank/encrypted/system/var/log";
        fsType = "zfs";
      };
    };

    zramSwap.enable = true;
    zramSwap.memoryPercent = 25; # ~3 GB from your 12 GB

    # Disko provides this swapDevices list automatically, but listing them here with the priority doesn't seem to have any impact, so we provide dropins below to override:
    # swapDevices = [
    #   {
    #     device = "/dev/mapper/dev-disk-byx2dpartlabel-swap0";
    #     priority = 100;
    #   }
    #   {
    #     device = "/dev/mapper/dev-disk-byx2dpartlabel-swap1";
    #     priority = 10;
    #   }
    # ];
    #
    systemd.units."dev-mapper-dev\\x2ddisk\\x2dbyx2dpartlabel\\x2dswap0.swap".text = ''
      [Swap]
      Options="pri=100"
    '';

    systemd.units."dev-mapper-dev\\x2ddisk\\x2dbyx2dpartlabel\\x2dswap1.swap".text = ''
      [Swap]
      Options="pri=10"
    '';

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";

    ## Networking
    networking = {
      useDHCP = false; # Disable the default networking, as we'll use systemd-networkd instead (see .systemd.network)
      hostName = "silo-1"; # Define your hostname.
      hostId = "e3e5cefd"; # provide a unique 32-bit ID, primarily for use by ZFS. This one was derived from /etc/machine-id
      networkmanager.enable = true;
      firewall.enable = false; # Disable the firewall altogether.
    };

    systemd.network = {
      enable = true;
      networks."10-lan" = {
        matchConfig.Name = "enp2s0";

        linkConfig.RequiredForOnline = "routable";

        networkConfig = {
          Address = "192.168.8.92/24";
          Gateway = "192.168.8.1";
          DNS = [ "192.168.8.1" ];
        };

        routingPolicyRules = [
          {
            # This rule catches packets that *originate* from the local node AND have set the source field to its own IP. Most traffic that is created on the node will not set source before this rule is evaluated, so will not be caught. Anything going to the main table will *skip* the Tailscale exit-node setup, which is the default otherwise.
            # Effect: Return traffic from the router to this node, back to the router! ie. ensure port-forwarding works -- without this packets arrive but returned traffic is sent via tailscale exit node and never reach client
            From = "192.168.8.92";
            Table = "main";
            Priority = 4900;
          }
          {
            # Route all traffic destined for the local LAN through the main table instead of Tailscale exit node
            # This allows the node to directly access other LAN devices
            To = "192.168.8.0/24";
            Table = "main";
            Priority = 4800;
          }
        ];
      };
      wait-online.enable = true;
    };

    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = true;

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

    ## Services

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    services.git-server = {
      enable = true;
      repoPath = "/tank/git";
      domainName = "git.liberty.rtlong.com git.silo-1.tailnet.rtlong.com";
      repos = [ ];
      port = 8013;
    };

    systemd.services.caddy = {
      unitConfig.After = [ "sops-nix.service" ];
      environment.AWS_CONFIG_FILE = config.sops.secrets.aws_credentials.path;
    };

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          security = "user";
          workgroup = "WORKGROUP";
          "server string" = "silo-1";
          "netbios name" = "silo-1";
          #"use sendfile" = "yes";
          #"max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "100. 192.168.8. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        "public-media" = {
          path = "/tank/public-media";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          # "force user" = "media";
          # "force group" = "media";
        };
        "homeassistant-backups" = {
          path = "/tank/backups/homeassistant";
        };
        "homeassistant-storage" = {
          path = "/tank//homeassistant";
        };
      };
    };

    users.users.homeassistant = {
      group = "homeassistant";
      initialHashedPassword = "$y$j9T$4GCQiiph0vT3/NWjs9lbL/$HDpZf0eApNMSWIZm7FRsAYchiPiVo.GAUSmzJeORd52";
      isSystemUser = true;
    };
    users.groups.homeassistant = { };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    services.kubo = {
      # IPFS
      enable = true;
    };

    services.nfs = {
      server.enable = true;
    };

    services.syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
      user = "syncthing";
      group = "users";
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraSetFlags = [
        #"--accept-routes"
        "--exit-node-allow-lan-access=true"
        "--exit-node=100.89.129.123" # us-bos-wg-102.mullvad.ts.net
        "--operator=${config.primaryUser.name}"
      ];
      permitCertUid = config.services.caddy.user;
    };

    services.restic = {
      server = {
        enable = true;
        dataDir = "/tank/restic";
        extraFlags = [
          "--debug"
        ];
      };
    };

    services.pinchflat = {
      enable = true;
      mediaDir = "/tank/public-media/youtube";
      user = "pinchflat";
      group = "media";
      selfhosted = true;
    };

    users.users.syncthing = {
      extraGroups = [
        "media"
        "downloaders"
        "users"
      ];
    };
    users.users.pinchflat = {
      extraGroups = [
        "media"
        "downloaders"
      ];
    };

    services.jellyfin = {
      enable = true;
      openFirewall = true;
      user = "jellyfin";
    };
    users.users.${config.services.jellyfin.user}.extraGroups = [
      "video"
      "media"
      "render"
    ];
    # enable hardware acceleration in Jellyfin
    # systemd.services.jellyfin = {
    #   environment = {
    #     LIBVA_DRIVER_NAME = "iHD";
    #   };
    #   serviceConfig = {
    #     SupplementaryGroups = [ "render" ];
    #     DevicePolicy = "auto";
    #     DeviceAllow = [ "/dev/dri/renderD128" ];
    #   };
    # };
    # hardware.opengl = {
    #   enable = true;
    #   extraPackages = with pkgs; [ intel-media-driver ]; # or intel-vaapi-driver if iHD still fails
    # };

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

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      hfsprogs
      zfs
      zfstools
      mlocate
      restic

      (pkgs.writeShellApplication {
        name = "nixos-install-usb";
        text = ''
          sudo nixos-install --root /mnt/ --flake ./nix-flake\#silo-1-usb-standby --no-root-password
        '';
      })

      # for Jellyfin HW acceleration:
      # jellyfin-ffmpeg
      # vaapiIntel
      # intel-media-driver
      # libva-utils
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
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
