{
  description = "rtlong nix flake";

  inputs = {
    # nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs?rev=b10b8846883e20f78b1c9d72ca691dee1dbe7ecb"; # NOTE: specifying this rev to avoid issue with tailscale in latest head as of 2025-03-08

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nb: snowfall demands this input be named `darwin`
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nb: snowfall demands this input be named `home-manager`
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        namespace = "rtlong";
        snowfall = {
          namespace = "rtlong";
        };
      };
    in
    lib.mkFlake {
      channels-config = {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "vscode"
            "spotify"
            "1password"
            "1password-cli"
          ];
      };

      overlays = with inputs; [
        self.outputs.overlays.my-patches
        inputs.emacs-overlay.overlays.default
      ];

      systems.modules.darwin = with inputs; [
        mac-app-util.darwinModules.default # enables Alfred/Spotlight to launch nix-controlled apps correctly
      ];
      homes.modules = with inputs; [
        spicetify-nix.homeManagerModules.default
        mac-app-util.homeManagerModules.default
      ];
    };
}
