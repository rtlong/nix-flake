{ config
, lib
, pkgs
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    programs.zsh.enable = true;
    # programs.bash.enable = true;

    programs.nix-index.enable = true;

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
        jq
        moreutils
        nawk
        nmap
        openssh
        openssl
        ripgrep
        ripgrep-all
        wget
      ];
    };

    rtlong = {
      nix = enabled;

      system = {
        fonts = enabled;
        input = enabled;
        # interface = enabled;
        networking = enabled;
      };
    };
  };
}
