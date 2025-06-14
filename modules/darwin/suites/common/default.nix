{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    # programs.zsh.enable = true;
    # programs.bash.enable = true;

    programs.nix-index.enable = true;

    # homebrew = {
    #   brews = [
    #     "bashdb"
    #     "gnu-sed"
    #   ];
    # };

    environment = {
      systemPackages = with pkgs; [
        bash-completion
        coreutils
        curl
        dig
        findutils
        fzf
        gawk
        gitFull
        gnugrep
        gnupg
        gnused
        gnutls
        htop
        iterm2
        jq
        moreutils
        nawk
        nmap
        openssh
        openssl
        unixtools.nettools
        ripgrep
        ripgrep-all
        wget
      ];
    };

    security.pam.services.sudo_local.touchIdAuth = true;

    system.primaryUser = config.primaryUser.name;

    rtlong = {
      nix = enabled;

      # tools = {
      #   homebrew = enabled;
      # };

      system = {
        fonts = enabled;
        input = enabled;
        interface = enabled;
        networking = enabled;
      };
    };
  };
}
