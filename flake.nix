{
  description = "fumuk-ligip-makit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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


    # nix-diff = {
    #   url = "github:Gabriella439/nix-diff";
    #   # inputs.nixpkgs.follows = "nixpkgs";
    # };

    local-ai = {
      url = "github:ck3d/nix-local-ai";
      # inputs.pkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      namespace = "rtlong";

      channels-config = {
        allowUnfree = true;

        # TODO: is it possible to use the predicate here?
        # nixpkgs.config.allowUnfreePredicate = pkg:
        #   builtins.elem (lib.getName pkg) [
        #     "vscode"
        #     "1password"
        #     "1password-cli"
        #   ];
      };

      overlays = with inputs; [
        # nix-diff.overlays.default
      ];

      systems.modules.darwin = with inputs; [
        mac-app-util.darwinModules.default # enables Alfred/Spotlight to launch nix-controlled apps correctly
      ];
      homes.modules = with inputs; [
        mac-app-util.homeManagerModules.default
      ];
    };
}
