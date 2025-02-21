{ lib
, pkgs
, inputs
, namespace
, system
, target
, format
, virtual
, systems
, config
, ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../../hardware-support/odroid-n2
  ];

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

  networking.hostName = "odroid"; # Define your hostname.
  # networking.hostId = ""; # provide a unique 32-bit ID, primarily for use by ZFS. This one was derived from /etc/machine-id

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
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    hashedPassword = "$y$j9T$78Su41EqfVOpXnSeZ3Vge0$LuN8CBD95WbvxP14VD00ktMLUciuzV8cu4.7SlNnC/D";
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZRO70wZDRS1UvbBxoA4X+RPfOrisXYX162V6z8mkVa"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMg7W6OlW+ET9I6lwyQT9hkZPhrcwgru8SMZhlsW/LmTIsgYWT5DMFWqj2FEV8uiV3LSKX17IDYfIqdESinujIaxTFXM7FVm02SrByvlGtc3MJfRucf0fRse1WBew30V/rB9g8FLMMZ5SV1q7P7DxDn+5irFjUbxZazuFr0mY/8E2xrVDsD7umRMaOHoywtSUkAMf3/Vjo9fJKScnb7nr4h6S6j1Gi0k8Agc0ztemMmfD7U1sXgxKhxH6GMV0ao1o9MDO+aXOjTCAWJBdLDrJ4f9IcjquztglXybSPO6jMj6NS3tbnO/yKcQRAUbwKEjC8qhcw8D/O5lFJmK9HSDZuwbz3Vg7G1+BXHbCW3koffHvDnCy6Cg2Uyd1y6gwXMMP7vSaqIEcfQCAZf/igM6ViCk394oUy5SgvNtDoY9xiVOINMxGPX6ultL0XH1YQUFhf/TXnaYeeuvTPC6ZJTKFBDiktFrW6Era3rfxOssh+5jyIPX/mXBSAV9h/jSX9hqc="
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWij+pYHcjojrSWugSYUDeEH8ojdi9Vp1RLikx2UyZwdAghnEuRCPodqGGG8dw1qPs5vMPot0XOSk46kJohaa0t8wYAjgL1kLAfOkd1P1vlmA//lX+dz/nYkkO0n+nbc1mjeQ9O43hK++YTcY8mMeWYGTc22hhRPhCzf3pOW8YS+vuHhhN+rs3/8K6hQVBqkgzuN5bR7ylqoXM9W23W2VZLrADkxQxdzDNpVeIgLmLb8Jjn1qySIxKxsN8AIlJHrZCDQbJ1TtIYtQVimMpG6QktpiROeYmo2r8Ik1wluy5nWyarkfgw5oLiZ9H9dd+Aby3P3GCbZ/Rdxk7KajQRAnfmZ9IVEcs5cWai+pHLJVnTsadwULBatb7r3N/9E9pzxBwyCi86c99Y5rJHMM1/eu8zu9Ss7DVQxbkpkAfHzBXWY3XmbWulwGh6eOPnKjt9q/LlJMxORuHgpLRPyNQfTIo7gvLrAAORqNPGxFBMIp6iQdcB21vv63ZKz3zxsb5Jrs="
      ];
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    jq
    htop
    tmux
    nixfmt-rfc-style
    hfsprogs
    usbutils
    dosfstools
    xz
    gzip
    bzip2
    unar
    vlc
    brave
    tailscale

  ];
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    desktopManager.mate.enable = true;
  };
  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.openssh = {
    enable = true;
  };

  services.avahi.enable = true;

  system.stateVersion = "24.11";
}
