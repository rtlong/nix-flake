{
  description = "fumuk-ligip-makit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin-ollama = {
      url = "github:Velnbur/nix-darwin/master";
      inputs.nixpkgs.follows = "nix-darwin";
    };

  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-darwin-ollama }:
    let
      overlay-ollama = final: prev: {
        velnbur = nix-darwin-ollama.packages.${prev.system};
      };

      configuration = { pkgs, lib, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = with pkgs; [
          vim
          #brave -- not yet available in nix-darwin
          iterm2
          git
          nmap
          awscli
          emacs
          vscode
          htop
          #_1password -- broken
          #_1password-gui -- broken
          dasht
          tailscale
          coreutils
          curl
          #hammerspoon -- need something to handle meh+{app} launch/focus bindings
          # pkgs.velnbur.ollama # broken? some hash mismatch
          utm
          direnv

          nixd
          nixpkgs-fmt
        ];

        nixpkgs.config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "vscode"
            "1password"
            "1password-cli"
          ];

        # use nix to manage homebrew packages;
        # homebrew = {
        #     enable = true;
        #     onActivation.cleanup = "uninstall";
        #     taps = [];
        #     brews = [ "ollama" ];
        #     casks = [];
        # };

        # Auto upgrade nix package and the daemon servic.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        security.pam.enableSudoTouchIdAuth = true;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#fumuk-ligip-makit
      darwinConfigurations."fumuk-ligip-makit" = nix-darwin.lib.darwinSystem {
        modules = [
          # ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-ollama ]; })
          configuration
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."fumuk-ligip-makit".pkgs;
    };
}
