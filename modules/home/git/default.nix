{
  lib,
  pkgs,
  inputs,
  namespace,
  system,
  target,
  format,
  virtual,
  host,
  config,
  ...
}:
let
  inherit (builtins) map listToAttrs;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;

  cfg = config.${namespace}.git;
in
{
  options.${namespace}.git = {
    enable = mkBoolOpt true "Whether or not to enable git";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      userEmail = config.primaryUser.email;
      userName = config.primaryUser.fullName;

      package = pkgs.gitMinimal;
      ignores = [
        ".project"
        "*.lck"
        "*.bak"
        "*~"

        # KDE Dingleberries
        ".directory"

        # Windows Dingleberries
        "Thumbs.db"

        # Mac OSX dingleberries
        ".DS_Store"
        ".~lock.*"

        "*.sassc"

        # ctags config file
        ".ctags"
        ".__ctags"

        "*.orig"

        "scratch"

        ".node-history"

        # vim plugin helptags or any vim tags files
        "tags"

        "#*#"
        ".#*"

        # Hint file for Emacs/projectile indicating explicit project roots.
        ".projectile"

        "*.code-workspace"

        "docker-compose.override.yml"

        ".zsh_history"
      ];

      aliases = {
        a = "add";
        aa = "add -A";
        ae = "add --edit";
        ap = "add --patch";
        b = "branch";
        br = "branch";
        c = "commit -v";
        ci = "commit -v";
        ci-retry = "commit -F .git/COMMIT_EDITMSG --edit";
        co = "checkout";
        com = "checkout master";
        d = "diff --word-diff";
        dc = "diff --cached";
        diff-plain = "!git -c core.pager=cat -c interactive.diffFilter=cat diff ";
        f = "fetch";
        fe = "fetch";
        ff = "merge --ff-only";
        l = "log";
        lg = "log --graph --pretty=custom --date=relative";
        ll = "log --graph --pretty=custom --date=relative";
        lla = "log --graph --pretty=custom --date=relative --exclude=origin/pr/* --exclude=gh-pages --remotes=origin --branches=*";
        llaa = "log --graph --pretty=custom --date=relative --all";
        log-json = "log --pretty=json";
        ls = "ls-files";
        mc = "merge --no-ff";
        mt = "mergetool";
        ps = "push";
        push-force = "push --force-with-lease";
        rb = "rebase";
        rbi = "rebase -i";
        rbc = "rebase --continue";
        rs = "reset";
        s = "status -sb";
        su = "submodule update --init";
        cw = "commit --all --no-edit --message wip";
      };

      # attributes = [""];

      signing = {
        signByDefault = true;
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZRO70wZDRS1UvbBxoA4X+RPfOrisXYX162V6z8mkVa";
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        format = "ssh";
      };

      lfs = {
        enable = true;
      };

      delta = {
        enable = true;
      };

      extraConfig = {
        color = {
          branch = "auto";
          diff = "auto";
          status = "auto";
          ui = "auto";
        };

        branch = {
          autoSetupMerge = "simple";
        };

        status.showUntrackedFiles = "all";

        rebase = {
          autoSquash = true;
          autoStash = true;
        };

        log = {
          abbrevCommit = true;
        };

        pretty = {
          # custom = "%C(red)%h%C(yellow)%d%Creset %s %C(green)(%ar) %C(bold blue)%aN%Creset %C(blue)%G?%Creset"
          custom = "%C(red)%h%C(yellow)%d%Creset %s %C(green)(%ar) %C(bold blue)%aN%Creset";
          json = ''{"commit\": \"%H\",\"authorName\": \"%aN\",\"authorEmail\":\"%aE\",\"date\": \"%aI\",\"subject\": \"%s\", \"parents\":\"%P\"}'';
        };

        core = {
          autocrlf = "input";
          # excludesfile = "~/.gitignore";
          whitespace = "trailing-space,-tab-in-indent,space-before-tab";
          editor = "code --wait";
        };

        stash.showPatch = true;

        fetch = {
          recurseSubmodules = true;
          prune = true;
        };

        diff.mnemonicPrefix = true;

        push = {
          default = "simple";
          autoSetupRemote = true;
        };

        grep = {
          lineNumber = true;
          patternType = "extended";
        };

        merge = {
          defaultToUpstream = true;
          tool = "diffmerge";
          conflictstyle = "diff3";
        };

        rerere.enabled = true;
        init.defaultBranch = "main";

        gitget = {
          root = "~/Code";
        };
      };

    };
    home.packages = with pkgs; [
      git-lfs
      git-get
      git-open
      # git-cola
      git-crypt
      git-doc
      # git-graph
      # git-annex
      # git-standup
    ];
  };
}
