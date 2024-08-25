{ config, pkgs, lib, local-ai, ... }:
let
  aws-vault-wrapper = (pkgs.writeShellApplication {
    name = "aws-vault";
    runtimeEnv = {
      AWS_VAULT_BACKEND = "file";
      AWS_SESSION_TOKEN_TTL = "36h";
      AWS_VAULT_FILE_PASSPHRASE = "op://qvutxi2zizeylilt23rflojdky/c5nz76at6k6vqx4cxhday5yg7u/password";
    };
    text = ''
      exec ${pkgs._1password}/bin/op --account my run -- "${pkgs.aws-vault}/bin/aws-vault" "$@"
    '';
  });

  repository_path = "${config.home.homeDirectory}/Code";

in
{
  home.stateVersion = "22.05";

  # programs.tmux = {
  #   enable = true;
  #   enableVim = true;
  #   enableSensible = true;
  #   enableMouse = true;
  # };

  # programs.vim = {
  #   enable = true;
  #   enableSensible = true;
  # };

  # # Htop
  # # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
  programs.htop.enable = true;
  programs.htop.settings.show_program_path = true;

  programs.zsh = {
    enable = true;
    envExtra = ''
      [[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
    '';
    shellAliases = {
      l = "ls -1A";
      ll = "ls -la";
      tf = "aws-vault exec opencounter -- terraform";
      dc = "docker compose";
    };
    initExtra = ''
      xtrace() { printf >&2 '+ %s\n' "$*"; "$@"; }

      git-get() {
        set -x
        git_url="$1"; shift
        [[ -n $git_url ]] || return 1
        dest="$(${pkgs.ruby}/bin/ruby $HOME/.local/bin/calculate-git-clone-destination "$git_url")"
        [[ -n $dest ]] || return 1

        if [[ -d $dest ]]; then
            cd "$dest"
            xtrace git fetch
        else
            xtrace git clone "$git_url" "$dest"
            cd "$dest"
        fi
        set +x
      }
    '';
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    autosuggestion.strategy = [
      "completion"
      "match_prev_cmd"
    ];
    history.extended = true;
    historySubstringSearch.enable = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      directory = {
        truncation_length = 10;
        truncate_to_repo = false; # truncates directory to root folder if in github repo
        # truncation_symbol = "…/";
        # fish_style_pwd_dir_length = 1;
        # read_only = " ";
        # style = "bold bright-blue";
        # repo_root_style = "bold bright-green";
        # repo_root_format = "[$before_root_path]($style)[$repo_root$path]($repo_root_style)[$read_only]($read_only_style) ";

        substitutions = {
          "~/Code/github.com/" = " ";
        };
      };
    };
  };
  programs.zoxide.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = {
    CODE_WORKSPACE_ROOT = repository_path;
  };
  home.packages = with pkgs; [
    # essential tools
    coreutils
    gitFull
    nawk
    findutils
    htop
    dig
    openssh
    nmap
    curl
    wget
    ripgrep
    ripgrep-all
    fd # find alternative - recommended by DoomEmacs
    fzf

    # editors
    # vim ## implied by programs.vim.enable and apparently incompatible with it
    emacsMacport
    vscode

    # docker # CLI
    # (pkgs.writeShellApplication {
    #   name = "docker";
    #   text = ''
    #     exec ${podman}/bin/podman "$@"
    #   '';
    # })
    # podman # installed through Podman Desktop app
    # podman-compose
    # kubectl
    # podman-desktop # broken as of 2024-08-19

    # brave -- not yet available in nix-darwin
    dasht
    direnv
    # hammerspoon -- not available
    iterm2
    jq
    ijq
    pick
    utm
    tealdeer # provides tldr
    tig

    # Auth tools
    _1password # -- op CLI tool
    aws-vault-wrapper
    yubikey-manager
    lastpass-cli

    # Webservice CLIs
    awscli
    github-cli

    # probably move to homemanager.packages once I set that up:
    # starship
    # zoxide
    bat

    # nix language server
    nixd
    nixpkgs-fmt

    # other language tools
    shellcheck
  ];

  # # Misc configuration files --------------------------------------------------------------------{{{

  # # https://docs.haskellstack.org/en/stable/yaml_configuration/#non-project-specific-config
  # home.file.".stack/config.yaml".text = lib.generators.toYAML { } {
  #   templates = {
  #     scm-init = "git";
  #     params = {
  #       author-name = "Your Name"; # config.programs.git.userName;
  #       author-email = "youremail@example.com"; # config.programs.git.userEmail;
  #       github-username = "yourusername";
  #     };
  #   };
  #   nix.enable = true;
  # };

  # home.file.".local/bin/docker" = {
  #   text = ''
  #     exec podman "$@"
  #   '';

  #   executable = true;
  # };

}
