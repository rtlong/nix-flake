{
  description = "fumuk-ligip-makit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    local-ai = {
      url = "github:ck3d/nix-local-ai";
      # inputs.pkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, home-manager, local-ai, ... }:
    let
      hostname = "fumuk-ligip-makit";
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#fumuk-ligip-makit
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        modules = [

          inputs.mac-app-util.darwinModules.default # enables Alfred/Spotlight to launch nix-controlled apps correctly
          ./system-configuration.nix
          ./lib/dnsmasq.nix # FIXME: PR this back info nix-darwin

          (args: {
            # Set Git commit hash for darwin-version.
            system.configurationRevision = self.rev or self.dirtyRev or null;
          })

          home-manager.darwinModules.home-manager

          ({ lib, ... }:
            {
              nixpkgs.config.allowUnfreePredicate = pkg:
                builtins.elem (lib.getName pkg) [
                  "vscode"
                  "1password"
                  "1password-cli"
                ];
              nixpkgs.overlays = [ ];

              home-manager.sharedModules = [
                inputs.mac-app-util.homeManagerModules.default
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = false;
              home-manager.users.ryanlong = import ./home.nix;
              home-manager.backupFileExtension = "hm-backup";
              # home-manager.extraSpecialArgs = [ local-ai ];

              users.users.ryanlong = {
                home = "/Users/ryanlong";
              };

              nix.settings.trusted-users = [ "ryanlong" ];
            })
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.${hostname}.pkgs;
    };
}
