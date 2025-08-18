{
  description = "rtlong nix flake";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixpkgs.url = "github:NixOS/nixpkgs?rev=b10b8846883e20f78b1c9d72ca691dee1dbe7ecb"; # NOTE: specifying this rev to avoid issue with tailscale in latest head as of 2025-03-08

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nb: snowfall demands this input be named `darwin`
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nb: snowfall demands this input be named `home-manager`
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
  };

  outputs =
    inputs:
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
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "vscode"
            "spotify"
            "1password"
            "1password-cli"
            "claude-code"
            "netdata"
          ];
      };

      overlays = with inputs; [
        inputs.emacs-overlay.overlays.default
        self.outputs.overlays.my-patches
      ];

      systems.modules.nixos = with inputs; [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
      ];
      systems.modules.darwin = with inputs; [
        mac-app-util.darwinModules.default # enables Alfred/Spotlight to launch nix-controlled apps correctly
        sops-nix.darwinModules.sops

      ];
      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
        mac-app-util.homeManagerModules.default
      ];
    };
}
