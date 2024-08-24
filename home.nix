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
      ll = "ls -la";
      tf = "aws-vault exec opencounter -- terraform";
      dc = "docker compose";
    };
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    autosuggestion.strategy = [
      "completion"
      "match_prev_cmd"
    ];
    history.extended = true;
    historySubstringSearch.enable = true;
  };

  programs.starship.enable = true;
  programs.zoxide.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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
