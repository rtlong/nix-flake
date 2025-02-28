{ config
, lib
, pkgs
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.common;
in
{
  options.${namespace}.suites.common = {
    enable = mkBoolOpt true "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bat
      coreutils
      curl
      dig
      direnv
      fd
      file
      findutils
      fzf
      jq
      killall
      lsof
      nawk
      nixd
      nixpkgs-fmt
      openssh
      pciutils
      ripgrep
      ripgrep-all
      rsync
      tldr
      unzip
      wget
      xclip
    ];
  };
}
