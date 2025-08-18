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
        enable = true;
        port = 8056;
        userExtraGroups = [
          "media"
        ];
      };
    };

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
      useDHCP = lib.mkDefault true;
      hostName = "silo-1"; # Define your hostname.
      hostId = "e3e5cefd"; # provide a unique 32-bit ID, primarily for use by ZFS. This one was derived from /etc/machine-id
      # interfaces.enp1s0.useDHCP = lib.mkDefault true;
      # interfaces.enp2s0.useDHCP = lib.mkDefault true;
      # interfaces.wlo1.useDHCP = lib.mkDefault true;
      networkmanager.enable = true;

      firewall.enable = false; # Disable the firewall altogether.
    };
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

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
        "--exit-node-allow-lan-access"
        "--exit-node=100.89.129.123" # us-bos-wg-102.mullvad.ts.net
      ];
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
