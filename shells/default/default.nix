{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # All other arguments come from NixPkgs. You can use `pkgs` to pull shells or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  mkShell,
  ...
}:

let
  deployScript =
    hostname: remoteFlakeLocation:
    pkgs.writeShellScriptBin "deploy-${hostname}" ''
      set -euo pipefail
      git add -A .
      rsync -aP --delete ./ ${hostname}:${remoteFlakeLocation}
      ssh -t ${hostname} sudo nixos-rebuild --flake ${remoteFlakeLocation} switch
    '';
in
mkShell {
  # Create your shell
  packages = with pkgs; [
    (deployScript "optiplex" "./nix-flake")
    (deployScript "odroid" "./nix-flake")
    (deployScript "silo-1" "./nix-flake")
  ];
}
