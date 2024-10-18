{ self, pkgs, lib, ... }: {
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

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
      "1password"
      "1password-cli"
    ];
  nixpkgs.overlays = [ ];

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

  # networking = {
  #   computerName = "";
  #   hostName = "";
  #   localHostName = "";
  # };

  # services.dnsmasq = {
  #   enable = true; ## TODO: this is buggy, notbly needs the bin/wait4path trick in the dnsmasq_module below -- good PR!
  # };

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
      wvous-tl-corner = 13;
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
