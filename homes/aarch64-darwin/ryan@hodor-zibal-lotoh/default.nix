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
  repository_path = "${config.home.homeDirectory}/Code";

  inherit (builtins) map listToAttrs;
in
{
  # rtlong = { # TODO: why can i not use `${namespace} = {` here? I get an infinite recursion error
  #   user = {
  #     enable = true;
  #     inherit (config.snowfallorg.user) name;
  #   };
  # };

  home.stateVersion = "22.05";

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    shortcut = "<space>";
  };

  # programs.vim = {
  #   enable = true;
  #   enableSensible = true;
  # };

  # # Htop
  # # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
  programs.htop = {
    enable = true;
    settings = {
      show_program_path = true;
    };
  };

  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    envExtra = ''
      [[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
    '';

    shellAliases =
      {
        l = "ls -1A";
        ll = "ls -la";
        tf = "terraform";
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

      autoload -U select-word-style
      select-word-style bash
      local WORDCHARS='*?_[]~=&;!#$%^(){}<>'
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
      shlvl = {
        disabled = false;
        threshold = 0;
      };
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
    # nmap
    liblinear
    curl
    wget
    ripgrep
    ripgrep-all
    rsync
    fd # find alternative - recommended by DoomEmacs
    fzf
    docker-credential-helpers
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
    pick # probably want to use fzf instead
    utm
    tealdeer # provides tldr
    tig

    # Auth tools
    _1password # -- op CLI tool
    yubikey-manager

    # Webservice CLIs
    awscli
    ssm-session-manager-plugin
    github-cli

    bat

    # nix language server
    nixd
    nixpkgs-fmt

    # other language tools
    shellcheck

    gephi
    pgadmin4-desktopmode
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
