{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt humans;

  human = humans.${config.human};
in
{
  options = with types; {
    human = mkOpt str "ryan" "The key of the human associated with this user account. Used to determine defaults";

    primaryUser = {
      name = mkOpt (nullOr str) human.username "The user account.";
      email = mkOpt str human.email "The email of the user.";
      fullName = mkOpt str human.fullName "The full name of the user.";
      hashedPassword = mkOpt (nullOr str) human.hashedPassword "The hashed password for the user.";
      sshPublicKeys = mkOpt (listOf str) human.sshPublicKeys "The SSH public keys for the user.";
      extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
      extraOptions = mkOpt attrs { } "Extra options passed to <option>users.users.<name></option>.";
    };
  };
}
