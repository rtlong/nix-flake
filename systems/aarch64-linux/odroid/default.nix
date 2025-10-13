{
  lib,
  pkgs,
  inputs,
  namespace,
  system,
  target,
  format,
  virtual,
  systems,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../../hardware-support/odroid-n2
  ];

  config = {
    ${namespace} = {
      # nb: only one of these "dynamic attributes" can exist in this attrset
      suites.server.enable = true;
    };
    networking.hostName = "odroid"; # Define your hostname.
    networking.hostId = "7e075a6b"; # provide a unique 32-bit ID, primarily for use by ZFS. This one was derived from /etc/machine-id

    boot = {
      # kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
      # supportedFilesystems = {
      #   zfs = lib.mkForce true;
      # };

      initrd = {
        availableKernelModules = [
          "usb_storage"
          "usbhid"
        ];
        # kernelModules = [ "zfs" ];
      };
    };
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      # hfsprogs
      # vlc
      # brave
      # zfs
      # zfstools
      # ddrescue
      # mjpg-streamer
    ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraSetFlags = [ ];
    };
    services.netdata = {
      enable = lib.mkForce false;
    };

    # E: ID_MODEL_ID=9422
    # E: ID_SERIAL=H264_USB_Camera_H264_USB_Camera_2020032801
    # E: ID_SERIAL_SHORT=2020032801
    # E: ID_VENDOR_ID=32e4
    # index=2 is the H264 device
    services.udev.extraRules = ''
      SUBSYSTEM=="video4linux", ENV{ID_SERIAL}=="H264_USB_Camera_H264_USB_Camera_2020032801", ATTR{index}=="2", SYMLINK+="video-janet", GROUP="video", MODE="0660", TAG+="uaccess"
    '';

    systemd.services.camera-tcp = {
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.ffmpeg}/bin/ffmpeg \
          -f v4l2 -input_format h264 -i /dev/video-janet \
          -c:v copy -f mpegts -listen 1 tcp://0.0.0.0:8090/
      '';
      unitConfig = {
        Restart = "always";
      };
    };
    networking.firewall.allowedTCPPorts = [ 8090 ];

    # Enable the X11 windowing system.
    services.xserver = {
      enable = false;
      # desktopManager.mate.enable = true;
    };

    # Configure keymap in X11
    # services.xserver.xkb.layout = "us";
    # services.xserver.xkb.options = "eurosign:e,caps:escape";

    # Enable CUPS to print documents.
    # services.printing.enable = true;

    system.stateVersion = "24.11";
  };
}
