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
    programs.nix-index.enable = true;

    environment = {
      systemPackages = with pkgs; [
        bash-completion
        coreutils
        curl
        dig
        findutils
        fzf
        gawk
        gitMinimal
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
        unixtools.net-tools
        ripgrep
        ripgrep-all
        wget
        wezterm
      ];
    };

    homebrew = {
      enable = true;
      brews = [ ];
    };

    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
      reattach = true;
    };

    system.primaryUser = config.primaryUser.name;

    rtlong = {
      nix = enabled;

      system = {
        fonts = enabled;
        input = enabled;
        interface = enabled;
        networking = enabled;
      };
    };
  };
}
