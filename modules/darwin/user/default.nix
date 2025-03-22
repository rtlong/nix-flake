{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.primaryUser;
in
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/user/default.nix")
  ];

  options.primaryUser = {
    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.zsh;

      openssh = {
        authorizedKeys.keys = cfg.sshPublicKeys;
      };
    };
  };
}
