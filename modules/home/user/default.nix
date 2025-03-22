{
  lib,
  pkgs,
  inputs,
  namespace,
  config,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt; # humans;
  cfg = config.primaryUser;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/user/default.nix") ];

  options.primaryUser = { };

  config = { };
}
