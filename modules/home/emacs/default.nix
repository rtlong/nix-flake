{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace,
  # The namespace used for your flake, defaulting to "internal" if not set.
  system,
  # The home architecture for this host (eg. `x86_64-linux`).
  target,
  # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format,
  # A normalized name for the home target (eg. `home`).
  virtual,
  # A boolean to determine whether this home is a virtual target using nixos-generators.
  host, # The host name for this home.

  # All other arguments come from the home home.
  config,
  ...
}:
let
  inherit (builtins) map listToAttrs;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt mkOpt;

  cfg = config.${namespace}.emacs;
in
{
  # imports = [ ];

  options.${namespace}.emacs = {
    enable = mkBoolOpt false "Whether or not to enable emacs";
    package = mkOpt lib.types.package pkgs.emacs30 "Which emacs package to use.";
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = cfg.package;
    };

    services.emacs = {
      enable = true;
      package = cfg.package;
    };

    programs.zsh.envExtra = ''
      export PATH="$HOME/.config/emacs/bin:$PATH"
    '';

    home.packages = with pkgs; [
      fontconfig
      coreutils-prefixed
      fd # find alternative - recommended by DoomEmacs
      binutils # native-comp needs 'as', provided by this

      ## Doom dependencies
      gitFull
      ripgrep
      gnutls # for TLS connectivity

      emacs-all-the-icons-fonts

      ## Optional dependencies
      fd # faster projectile indexing
      imagemagick # for image-dired
      # (mkIf (config.programs.gnupg.agent.enable)
      #   pinentry-emacs) # in-emacs gnupg prompts
      zstd # for undo-fu-session/undo-tree compression

      ## Module dependencies
      # :email mu4e
      mu
      isync
      # :checkers spell
      # (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
      # :tools editorconfig
      editorconfig-core-c # per-project style config
      # :tools lookup & :lang org +roam
      sqlite
      graphviz # for org-roam graph
      # :lang cc
      clang-tools
      # :lang latex & :lang org (latex previews)
      texlive.combined.scheme-medium
      # :lang beancount
      beancount
      fava
      # :lang nix
      age
      markdownlint-cli
      pandoc

      nerd-fonts.symbols-only
    ];

  };
}
