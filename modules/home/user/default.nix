{ lib
, pkgs
, inputs
, namespace
, config
, ...
}:
let
  inherit (builtins) map listToAttrs;
  inherit (lib) types mkIf mkMerge;
  inherit (lib.${namespace}) enabled mkBoolOpt mkOpt humans;

  cfg = config.${namespace}.user;

  snowfallUser = config.snowfallorg.user.name;
  human = humans.${cfg.human};
in
{
  options.${namespace}.user = {
    human = mkOpt types.str snowfallUser "The key of the human associated with this user account. Used to determine defaults";

    email = mkOpt types.str human.email "The email of the user.";
    fullName = mkOpt types.str human.fullName "The full name of the user.";
    name = mkOpt (types.nullOr types.str) human.username "The user account.";
  };

  # config = mkIf cfg.enable (mkMerge [ ]);
}
