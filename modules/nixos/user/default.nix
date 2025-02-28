{ config
, lib
, pkgs
, namespace
, ...
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

  options.primaryUser = with types; {
    uid = mkOpt (nullOr int) 1000 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      isNormalUser = true;
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ] ++ cfg.extraGroups;
      inherit (cfg) hashedPassword;
      openssh = {
        authorizedKeys.keys = cfg.sshPublicKeys;
      };
    };
  };
}
