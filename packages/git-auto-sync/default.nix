{
  config,
  lib,
  pkgs,
  ...
}:

pkgs.writeShellApplication {
  name = "git-auto-sync";
  runtimeInputs = [
    pkgs.python3
    pkgs.git
  ];
  text = ''
    exec python3 ${./sync.py} "$@"
  '';
}
