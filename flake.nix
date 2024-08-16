{
  description = "fumuk-ligip-makit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, ... }:
    let
      system = "aarch64-darwin";

      inherit (nixpkgs) lib;
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (builtins.traceVal (lib.getName pkg)) [
        "vscode"
        "1password"
        "1password-cli"
      ];

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-darwin.overlays.default ];
      };

      ykman-gui = (pkgs.callPackage ./lib/ykman-gui { });

      configuration = { pkgs, lib, ... }: {
        # List packages installed in system profile. To search by name, run:
        environment.systemPackages = with pkgs; [
          # essential tools
          coreutils
          gitFull
          nawk
          findutils
          htop
          dig
          nmap
          curl
          wget
          ripgrep
          ripgrep-all
          fzf

          # editors
          # vim ## implied by programs.vim.enable and apparently incompatible with it
          emacs
          vscode

          # other software/tools
          _1password # -- op CLI tool
          # aws-mfa
          aws-vault
          awscli
          # brave -- not yet available in nix-darwin
          colima # replacement for Docker Desktop
          dasht
          direnv
          docker
          # hammerspoon -- need something to handle meh+{app} launch/focus bindings
          iterm2
          jq
          fx # tool like JQ with interactive filtering
          nix-direnv
          pick
          utm
          yubikey-manager
          # ykman-gui

          lastpass-cli
          tealdeer # provides tldr
          tig

          # probably move to homemanager.packages once I set that up:
          starship
          zoxide
          bat

          # nix language server
          nixd
          nixpkgs-fmt

          # other language tools
          shellcheck

        ];

        fonts.packages = with pkgs; [
          (nerdfonts.override { fonts = [ "OpenDyslexic" "Lilex" "FiraCode" ]; })
          open-dyslexic
          font-awesome
        ];

        # # use nix to manage homebrew packages; have to install Homebrew separately
        # homebrew = {
        #   enable = true;
        #   onActivation.cleanup = "uninstall";
        #   taps = [ ];
        #   brews = [ "nmap" ];
        #   casks = [ ];
        # };

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina

        programs.bash.enable = true;
        programs.direnv.enable = true;
        programs.direnv.nix-direnv.enable = true;
        environment.shellAliases = {
          ll = "ls -l";
        };
        programs.nix-index.enable = true;
        programs.tmux = {
          enable = true;
          enableVim = true;
          enableSensible = true;
          enableMouse = true;
        };
        programs.vim = {
          enable = true;
          enableSensible = true;
        };

        # networking = {
        #   computerName = "";
        #   hostName = "";
        #   localHostName = "";
        # };

        services.dnsmasq = {
          enable = true;
          addresses = {
            test = "127.0.0.1"; # redirect all queries for *.test TLD to localhost
            localhost = "127.0.0.1"; # redirect all queries for *.localhost TLD to localhost
          };
        };

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

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Auto upgrade nix package and the daemon servic.
        services.nix-daemon.enable = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";
        nix.settings.trusted-users = [ "ryanlong" ];

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = system;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#fumuk-ligip-makit
      darwinConfigurations."fumuk-ligip-makit" = nix-darwin.lib.darwinSystem {
        inherit pkgs;

        modules = [
          inputs.mac-app-util.darwinModules.default # enables Alfred/Spotlight to launch nix-controlled apps correctly
          configuration
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."fumuk-ligip-makit".pkgs;

      # inherit ykman-gui;
    };
}
