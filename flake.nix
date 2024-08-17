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
          openssh
          # openssh_gssapi
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
          ijq
          # fx # tool like JQ with interactive filtering
          nix-direnv
          pick
          utm
          yubikey-manager
          lastpass-cli
          tealdeer # provides tldr
          tig
          github-cli

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

        # services.dnsmasq = {
        #   enable = true; ## TODO: this is buggy, notbly needs the bin/wait4path trick in the dnsmasq module below -- good PR!
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

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Auto upgrade nix package and the daemon servic.
        services.nix-daemon.enable = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";
        nix.settings.trusted-users = [ "ryanlong" ];

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;
      };

      dnsmasq_module = { config, lib, pkgs, ... }:
        with lib;
        let
          mapA = f: attrs: with builtins; attrValues (mapAttrs f attrs);
          package = pkgs.dnsmasq;
          addresses = {
            test = "127.0.0.1"; # redirect all queries for *.test TLD to localhost
            localhost = "127.0.0.1"; # redirect all queries for *.localhost TLD to localhost
          };
          bind = "127.0.0.1";
          port = 53;
          args = [
            "--listen-address=${bind}"
            "--port=${toString port}"
            "--no-daemon"
          ] ++ (mapA (domain: addr: "--address=/${domain}/${addr}") addresses);
        in
        {
          environment.systemPackages = [ package ];

          launchd.daemons.dnsmasq = {
            # serviceConfig.Debug = true;
            serviceConfig.ProgramArguments = [
              "/bin/sh"
              "-c"
              "/bin/wait4path ${package} &amp;&amp; exec ${package}/bin/dnsmasq ${toString args}"
            ];
            serviceConfig.StandardOutPath = /var/log/dnsmasq.log;
            serviceConfig.StandardErrorPath = /var/log/dnsmasq.log;
          };

          environment.etc = builtins.listToAttrs (builtins.map
            (domain: {
              name = "resolver/${domain}";
              value = {
                enable = true;
                text = ''
                  port ${toString port}
                  nameserver ${bind}
                '';
              };
            })
            (builtins.attrNames addresses));
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#fumuk-ligip-makit
      darwinConfigurations."fumuk-ligip-makit" = nix-darwin.lib.darwinSystem {
        modules = [
          inputs.mac-app-util.darwinModules.default # enables Alfred/Spotlight to launch nix-controlled apps correctly
          dnsmasq_module
          configuration
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."fumuk-ligip-makit".pkgs;
    };
}
