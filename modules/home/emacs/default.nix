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

  emacsActivate = (
    pkgs.writeShellApplication {
      name = "emacs-activate";
      text = ''
        # NB: I had issues with emacsclient -r -- when no frame exists it wouldn't create one, so using this custom function to make it a little more reliable:
        ${emacsPkg}/bin/emacsclient -n -e "(my/raise-or-create-frame)"
        emacs_pid=$(${emacsPkg}/bin/emacsclient -n -e "(emacs-pid)")

        # Emacs does not reliably bring the frame to the foreground, so this AppleScript helps:
        osascript <<-EOF
          tell application "System Events"
            set frontmost of the first process whose unix id is ''${emacs_pid} to true
          end tell
        EOF
      '';
    }
  );

in
{
  options.${namespace}.emacs = {
    enable = mkBoolOpt false "Whether or not to enable emacs";
    package = mkOpt lib.types.package emacsPkg "Which emacs package to use.";
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
    launchd.agents.emacs.config = {
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
      emacsActivate # referenced by skhd config

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

    home.file.".config/doom/nix-helpers/activate.el" = {
      text = ''
        (defun my/raise-or-create-frame ()
          "Raise an existing frame or create a new one if none exists."
          (if (frame-list)  ;; Check if there are any frames
              (let ((frame (selected-frame)))
                (raise-frame frame)
                (select-frame-set-input-focus frame))
            (make-frame)))  ;; Create a new frame if none exists
      '';
    };
  };
}
