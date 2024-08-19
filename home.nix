{ config, pkgs, lib, local-ai, ... }:
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
    fzf

    # editors
    # vim ## implied by programs.vim.enable and apparently incompatible with it
    emacs
    vscode

    colima # replacement for Docker Desktop
    docker # CLI

    # brave -- not yet available in nix-darwin
    dasht
    direnv
    # hammerspoon -- not available
    iterm2
    jq
    ijq
    nix-direnv
    pick
    utm
    tealdeer # provides tldr
    tig

    # Auth tools
    _1password # -- op CLI tool
    aws-vault
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

}
