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
    rtlong = {
      nix = enabled;

      system = {
        fonts = enabled;
        input = enabled;
        # interface = enabled;
        networking = enabled;
      };
    };

    programs.zsh.enable = true;

    services.avahi.enable = true;

    services.openssh = {
      enable = true;
    };

    users.users.root = {
      isNormalUser = false;
      hashedPassword = config.primaryUser.hashedPassword;
    };

    security = {
      pam = {
        services = {
          sudo = {
            sshAgentAuth = true;
          };
        };

        sshAgentAuth = {
          enable = true;
          # authorizedKeysFiles = [
          #   "/home/ryan/.ssh/authorized_keys"
          # ];
        };
      };
    };

    environment = {
      systemPackages = with pkgs; [
        bash-completion
        busybox
        bzip2
        coreutils
        curl
        dig
        dosfstools
        efibooteditor
        efibootmgr
        findutils
        fzf
        gawk
        gitFull
        gnugrep
        gnupg
        gnused
        gnutls
        gzip
        htop
        iotop
        jq
        moreutils
        nawk
        nmap
        openssh
        openssl
        ripgrep
        ripgrep-all
        tmux
        unar
        usbtop
        usbutils
        vim
        wget
        xz
      ];
    };
  };
}
