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
  system
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

  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.common;
in
{
  imports = [ ];

  options.${namespace}.suites.common = {
    enable = mkBoolOpt true "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable
    {
      programs.tmux = {
        enable = true;
        keyMode = "vi";
        shortcut = "<space>";
        baseIndex = 1;
        clock24 = true;
        historyLimit = 10000;
        mouse = true;
        newSession = true;
        prefix = "C-Space";
        shell = "${pkgs.zsh}/bin/zsh";

        extraConfig = ''
          unbind-key  C-Down
          unbind-key  C-Left
          unbind-key  C-Right
          unbind-key  C-Up
          bind-key     o              last-window
          bind-key     C-c            new-window -c "#{pane_current_path}"
          bind-key     c              new-window
          bind-key -r  h              select-pane -L
          bind-key -r  j              select-pane -D
          bind-key -r  k              select-pane -U
          bind-key -r  l              select-pane -R
          bind-key -r  p              previous-window
          bind-key -r  n              next-window
          bind-key     s              split-window
          bind-key     C-s            split-window -c "#{pane_current_path}"
          bind-key     v              split-window -h
          bind-key     C-v            split-window -h -c "#{pane_current_path}"

          set-option -g   renumber-windows              on
          set-option -g   visual-activity               on
          set-option -g   visual-bell                   off
          set-option -g   visual-silence                on
          set-option -s   focus-events                  on
          set-option -wg  automatic-rename              on
          set-option -g   detach-on-destroy             on
          set-option -wg  pane-active-border-style      'bg=black,fg=red'
          set-option -wg  pane-border-style             'bg=black,fg=#999999'
          set-option -g   message-command-style         'fg=black,bg=yellow'
          set-option -g   message-style                 'fg=black,bg=yellow'
          set-option -wg  window-status-current-style   'bg=#333333,fg=yellow'
          set-option -wg  window-status-last-style      'fg=yellow'
          set-option -g   status-interval               5
          set-option -g   status-left                   "#{?client_prefix,#[bg=magenta]#[fg=black],}[#S]#[default] "
          set-option -g   status-right                  "#(loadavg | awk '{print $1}')x #[fg=green]#{=21:pane_title} #[fg=cyan]#H #[fg=red]%H:%M %d-%b"
          set-option -g   status-right-length           60
          set-option -g   status-style                  'fg=#ffffff,bg=#111111'
          set-option -g   set-titles on
          set-option -g   set-titles-string '#{window_name}:#{pane_title}'
        '';
      };

      programs.htop = {
        enable = true;
        settings = {
          show_program_path = true;
          color_scheme = 6;
          cpu_count_from_one = 0;
          delay = 15;
          fields = with config.lib.htop.fields; [
            PID
            USER
            PRIORITY
            NICE
            M_SIZE
            M_RESIDENT
            M_SHARE
            STATE
            PERCENT_CPU
            PERCENT_MEM
            TIME
            COMM
          ];
          highlight_base_name = 1;
          highlight_megabytes = 1;
          highlight_threads = 1;
        } // (with config.lib.htop; leftMeters [
          (bar "AllCPUs2")
          (bar "Memory")
          (bar "Swap")
          (text "Zram")
        ]) // (with config.lib.htop; rightMeters [
          (text "Tasks")
          (text "LoadAverage")
          (text "Uptime")
          (text "Systemd")
        ]);

      };

      home.shellAliases = {
        l = "ls -1A";
        ll = "ls -la";
        tf = "terraform";
        dc = "docker compose";
      };

      programs.bash.enable = true;

      programs.zsh = {
        enable = true;
        envExtra = ''
          [[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
        '';

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

          setopt extendedglob
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
        dig
        openssh
        # nmap
        liblinear
        curl
        wget
        ripgrep
        ripgrep-all
        rsync
        fzf
        docker-credential-helpers

        # editors
        vscode

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
        _1password-cli # -- op CLI tool
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
    };
}
