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

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "@wheel"
      "nixbuild"
    ];
  };

  security.sudo.extraRules = [
    # Allow execution of "nixos-rebuild switch" by user `nixbuild` without a password.
    {
      users = [
        "nixbuild"
        "ryan"
      ];
      commands = [
        {
          command = "/nix/store/*/bin/switch-to-configuration";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix-store";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix-env";
          options = [ "NOPASSWD" ];
        }
        {
          command = ''/bin/sh -c "readlink -e /nix/var/nix/profiles/system || readlink -e /run/current-system"'';
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix-collect-garbage";
          options = [ "NOPASSWD" ];
        }
        {
          /*
            HACK: this sucks but IDK how to wildcard this correctly to capture these two run commands. When running

            nixos-rebuild --no-build-nix --build-host optiplex --target-host optiplex --flake '.#optiplex' --max-jobs 0 --use-remote-sudo --fast --verbose switch

            the following commands are executed using sudo

            sudo systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER= --collect --no-ask-password --pipe --quiet --same-dir --service-type=exec --unit=nixos-rebuild-switch-to-configuration --wait true
            sudo env -i LOCALE_ARCHIVE= NIXOS_INSTALL_BOOTLOADER= /nix/store/20p1kzk03xl4pkjiqrn1r4kkar4v408n-nixos-system-optiplex-24.11.20240719.1d9c2c9/bin/switch-to-configuration switch
          */
          command = "/run/current-system/sw/bin/systemd-run *";
          options = [ "NOPASSWD" ];
        }
      ];
    }

  ];
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

  networking.hostName = "optiplex"; # Define your hostname.
  networking.hostId = "267498f7"; # provide a unique 32-bit ID, primarily for use by ZFS. This one was derived from /etc/machine-id

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nixbuild = {
    isNormalUser = true;
    homeMode = "500";
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdnGCx6WoS89hvmoMrZV+/1i3/n66iJsHbRM8R04/NV root@sifal-logah-pohin.local"
      ];
    };
  };

  users.users.root = {
    isNormalUser = false;
    hashedPassword = "$y$j9T$78Su41EqfVOpXnSeZ3Vge0$LuN8CBD95WbvxP14VD00ktMLUciuzV8cu4.7SlNnC/D";
  };

  users.users.ryan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "media" ]; # Enable ‘sudo’ for the user.
    hashedPassword = "$y$j9T$78Su41EqfVOpXnSeZ3Vge0$LuN8CBD95WbvxP14VD00ktMLUciuzV8cu4.7SlNnC/D";
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZRO70wZDRS1UvbBxoA4X+RPfOrisXYX162V6z8mkVa"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMg7W6OlW+ET9I6lwyQT9hkZPhrcwgru8SMZhlsW/LmTIsgYWT5DMFWqj2FEV8uiV3LSKX17IDYfIqdESinujIaxTFXM7FVm02SrByvlGtc3MJfRucf0fRse1WBew30V/rB9g8FLMMZ5SV1q7P7DxDn+5irFjUbxZazuFr0mY/8E2xrVDsD7umRMaOHoywtSUkAMf3/Vjo9fJKScnb7nr4h6S6j1Gi0k8Agc0ztemMmfD7U1sXgxKhxH6GMV0ao1o9MDO+aXOjTCAWJBdLDrJ4f9IcjquztglXybSPO6jMj6NS3tbnO/yKcQRAUbwKEjC8qhcw8D/O5lFJmK9HSDZuwbz3Vg7G1+BXHbCW3koffHvDnCy6Cg2Uyd1y6gwXMMP7vSaqIEcfQCAZf/igM6ViCk394oUy5SgvNtDoY9xiVOINMxGPX6ultL0XH1YQUFhf/TXnaYeeuvTPC6ZJTKFBDiktFrW6Era3rfxOssh+5jyIPX/mXBSAV9h/jSX9hqc="
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWij+pYHcjojrSWugSYUDeEH8ojdi9Vp1RLikx2UyZwdAghnEuRCPodqGGG8dw1qPs5vMPot0XOSk46kJohaa0t8wYAjgL1kLAfOkd1P1vlmA//lX+dz/nYkkO0n+nbc1mjeQ9O43hK++YTcY8mMeWYGTc22hhRPhCzf3pOW8YS+vuHhhN+rs3/8K6hQVBqkgzuN5bR7ylqoXM9W23W2VZLrADkxQxdzDNpVeIgLmLb8Jjn1qySIxKxsN8AIlJHrZCDQbJ1TtIYtQVimMpG6QktpiROeYmo2r8Ik1wluy5nWyarkfgw5oLiZ9H9dd+Aby3P3GCbZ/Rdxk7KajQRAnfmZ9IVEcs5cWai+pHLJVnTsadwULBatb7r3N/9E9pzxBwyCi86c99Y5rJHMM1/eu8zu9Ss7DVQxbkpkAfHzBXWY3XmbWulwGh6eOPnKjt9q/LlJMxORuHgpLRPyNQfTIo7gvLrAAORqNPGxFBMIp6iQdcB21vv63ZKz3zxsb5Jrs="
      ];
    };
  };

  users.groups.media = {
    name = "media";
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      git
      jq
      htop
      tmux
      nixfmt-rfc-style
      hfsprogs
    ];

  #  programs.nix-ld = {
  #    enable = true;
  #    package = inputs.nix-ld-rs.packages."${pkgs.system}".nix-ld-rs;
  #  };

  # List services that you want to enable:

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi.enable = true;

  services.k3s.enable = true;
  services.k3s.extraFlags = [ "--tls-san=optiplex,optiplex.liberty.rtlong.com" ];

  services.ollama.enable = true;

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

  services.openssh.enable = true;

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # Disable the firewall altogether.
  networking.firewall.enable = false;

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
}
