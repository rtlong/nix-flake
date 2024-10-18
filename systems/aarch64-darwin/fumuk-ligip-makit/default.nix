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
  # Build darwin flake using:
  # $ darwin-rebuild build --flake .#fumuk-ligip-makit
  # modules = [

  # (args: {
  #   # Set Git commit hash for darwin-version.
  #   system.configurationRevision = self.rev or self.dirtyRev or null;
  # })


  # home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = false;
  # home-manager.users.ryanlong = import ./home.nix;
  # home-manager.backupFileExtension = "hm-backup";
  # home-manager.extraSpecialArgs = [ local-ai ];

  users.users.ryanlong = {
    home = "/Users/ryanlong";
  };

  nix.settings.trusted-users = [ "ryanlong" ];

  # List packages installed in system profile. To search by name, run:
  environment.systemPackages = with pkgs; [
    # essential tools
    coreutils
    gitFull
    nawk
    findutils
    htop
    dig
    openssh
    nmap
    curl
    wget
    ripgrep
    ripgrep-all
    fzf

    colima # replacement for Docker Desktop
    docker # CLI

    jq
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "OpenDyslexic" "Lilex" "FiraCode" ]; })
    open-dyslexic
    font-awesome
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.bash.enable = true;

  environment.shellAliases = {
    ll = "ls -l";
  };

  programs.nix-index.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  system.defaults = {
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleKeyboardUIMode = 3; # enable full keyboard control
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSTableViewDefaultSizeMode = 1;
      NSWindowShouldDragOnGesture = true;
    };
    # WindowManager.AutoHide = true;
    alf = {
      allowdownloadsignedenabled = 1;
      allowsignedenabled = 1;
    };

    dock = {
      appswitcher-all-displays = false;
      autohide = true;
      mru-spaces = false;

      # hot corners
      wvous-bl-corner = 1; # disabled
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = false;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
    };

    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 2; # 2 = never
      ShowDayOfMonth = false;
      ShowDayOfWeek = false;
      ShowSeconds = false;
    };

    # smb.NetBIOSName = "";
    spaces.spans-displays = false; # false = each physical display has a separate space (Mac default) true = one space spans across all physical displays

    trackpad.ActuationStrength = 0; # silent clicking

    # universalaccess.mouseDriverCursorSize = 2.0;
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  # Auto upgrade nix package and the daemon servic.
  services.nix-daemon.enable = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
