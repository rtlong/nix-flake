{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.emacs;

  basePkg = pkgs.emacs30;
  emacsPkg = (pkgs.emacsPackagesFor basePkg).emacsWithPackages (epkgs: [
    epkgs.vterm
  ]);

in
{
  options.${namespace}.emacs = {
    enable = mkBoolOpt false "Whether or not to enable emacs";
    enableServer = mkBoolOpt false "Whether or not to run Emacs server in the background as a service";
    package = mkOpt lib.types.package emacsPkg "Which emacs package to use.";
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = cfg.package;
    };

    services.emacs = {
      enable = cfg.enableServer;
      package = cfg.package;
    };

    launchd.agents.emacs.config = mkIf cfg.enableServer {
      KeepAlive = mkForce true;
      EnvironmentVariables = (
        mkIf config.${namespace}.ghostty.enable {
          TERMINFO = "/Applications/Ghostty.app/Contents/Resources/terminfo/"; # FIX *ERROR*: Terminal type xterm-ghostty is not defined when invoking emacsclient from Ghostty
        }
      );
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
      (aspellWithDicts (
        ds: with ds; [
          en
          en-computers
        ]
      ))
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
