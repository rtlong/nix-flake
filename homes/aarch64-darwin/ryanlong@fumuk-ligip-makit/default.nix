{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib
, # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs
, # You also have access to your flake's inputs.
  inputs
, # Additional metadata is provided by Snowfall Lib.
  namespace
, # The namespace used for your flake, defaulting to "internal" if not set.
  home
, # The home architecture for this host (eg. `x86_64-linux`).
  target
, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format
, # A normalized name for the home target (eg. `home`).
  virtual
, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host
, # The host name for this home.

  # All other arguments come from the home home.
  config
, ...
}:
let
  inherit (builtins) map listToAttrs;

  aws-vault-wrapper = (pkgs.writeShellApplication {
    name = "aws-vault";
    runtimeEnv = {
      AWS_VAULT_BACKEND = "file";
      AWS_SESSION_TOKEN_TTL = "36h";
    };
    excludeShellChecks = [ "SC2209" ];
    text = ''
      exec env AWS_VAULT_FILE_PASSPHRASE="$(${pkgs._1password}/bin/op --account my read op://qvutxi2zizeylilt23rflojdky/c5nz76at6k6vqx4cxhday5yg7u/password)" \
        "${pkgs.aws-vault}/bin/aws-vault" "$@"
    '';
  });

in
{
  home.shellAliases = {
    tf = "terraform";
    dc = "docker compose";
    with-creds = "op run -- aws-vault exec opencounter --";
  } // (listToAttrs (map
    (cmd: {
      name = cmd;
      value = "with-creds ${cmd}";
    }) [ "rails" "sidekiq" "overmind" "terraform" ]));

  # home.packages = with pkgs; [
  #   # Auth tools
  #   aws-vault-wrapper
  #   yubikey-manager
  #   lastpass-cli
  #   _1password-cli # -- op CLI tool

  #   # Webservice CLIs
  #   awscli
  #   ssm-session-manager-plugin
  #   github-cli

  #   gephi
  #   pgadmin4-desktopmode
  # ];

  home.stateVersion = "22.05";
}
