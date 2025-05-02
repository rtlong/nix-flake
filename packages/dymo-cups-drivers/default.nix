{
  config,
  lib,
  pkgs,
  stdenv,
  ...
}:

let
  drivers-src = pkgs.fetchFromGitHub {
    owner = "matthiasbock";
    repo = "dymo-cups-drivers";
    rev = "eb2ad031114f4aaaf9b8d576d9596b1a9585c434";
    hash = "";
  };
in

stdenv.mkDerivation {
  # Create your package

}
