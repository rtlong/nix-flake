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
    alf.allowdownloadsignedenabled = 1;
    alf.allowsignedenabled = 1;

    dock.appswitcher-all-displays = true;
    dock.autohide = true;
    dock.mru-spaces = false;

    # hot corners
    dock.wvous-bl-corner = 1; # disabled
    dock.wvous-br-corner = 1;
    dock.wvous-tl-corner = 1;
    dock.wvous-tr-corner = 1;

    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder.CreateDesktop = false;
    finder.FXEnableExtensionChangeWarning = false;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
    finder._FXShowPosixPathInTitle = true;

    menuExtraClock.Show24Hour = true;
    menuExtraClock.ShowDate = 2; # 2 = never
    menuExtraClock.ShowDayOfMonth = false;
    menuExtraClock.ShowDayOfWeek = false;
    menuExtraClock.ShowSeconds = false;

    # smb.NetBIOSName = "";
    spaces.spans-displays = true; # false = each physical display has a separate space (Mac default) true = one space spans across all physical displays

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
