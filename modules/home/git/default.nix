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
  inherit (builtins) map listToAttrs;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;

  cfg = config.${namespace}.git;

  calculate-clone-destination = pkgs.writeScript "calculate-git-clone-application"
    ''
      #!${pkgs.ruby}/bin/ruby

      require 'uri'

      SSH_INPUT_PATTERN = /^\w+@(?<host>([a-z0-9-]+\.)*[a-z0-9-]+):(?<path>.+)$/i
      CODE_LIBRARY_ROOT = ENV.fetch('CODE_WORKSPACE_ROOT')

      input = ARGV[0]

      if (m = SSH_INPUT_PATTERN.match(input))
        host = m[:host]
        path = m[:path]

      else
        uri = URI(input)
        host = uri.host
        path = uri.path
      end

      clone_dest = File.join(CODE_LIBRARY_ROOT, host, path.sub(/\.git$/, ""))

      puts clone_dest
    '';

  git-get-function = ''
    git-get() {
      git_url="$1"; shift
      [[ -n $git_url ]] || return 1
      dest="$( ${calculate-clone-destination} "$git_url" )"
      [[ -n $dest ]] || return 1

      if [[ -d $dest ]]; then
        cd "$dest"
        git fetch
      else
        git clone "$git_url" "$dest"
        cd "$dest"
      fi
    }
  '';

in
{
  options.${namespace}.git = {
    enable = mkBoolOpt true "Whether or not to enable git";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      userEmail = config.${namespace}.user.email;
      userName = config.${namespace}.user.fullName;

      package = pkgs.gitFull;
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
        rb = "rebase";
        rbi = "rebase -i";
        rbc = "rebase --continue";
        rs = "reset";
        s = "status -sb";
        su = "submodule update --init";
        cw = "commit --all --no-edit --message wip";
      };

      # attributes = [""];

      # signing = {
      # signByDefault = true;
      # key = "";
      # gpgPath = "";
      # };

      lfs = {
        enable = true;
      };

      difftastic = {
        enable = true;
      };

      extraConfig = {
        color = {
          branch = "auto";
          diff = "auto";
          status = "auto";
          ui = "auto";
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
      };
    };

    programs.zsh.initExtra = git-get-function;
  };
}
