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

  networking.hostName = "odroid"; # Define your hostname.

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    hfsprogs
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


  system.stateVersion = "24.11";
}
