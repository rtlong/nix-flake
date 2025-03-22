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
  inherit (builtins)
    match
    readFile
    fetchGit
    isList
    ;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt compose filterLines;

  cfg = config.${namespace}.dircolors;

  repo = fetchGit {
    url = "https://github.com/trapd00r/LS_COLORS.git";
    ref = "master";
    rev = "20cc87c21f5f54cf86be7e5867af9efc65b8b4e3";
  };

  hasContent = compose [
    isList
    (match "\s*[^#]+.*")
  ];
  filterOutComments = filterLines hasContent;
in
{
  options.${namespace}.dircolors = {
    enable = mkBoolOpt false "Whether or not to enable dircolors configuration.";
  };

  config = mkIf cfg.enable {
    programs.dircolors = {
      enable = true;
      extraConfig = filterOutComments (readFile "${repo}/LS_COLORS");
    };
  };
}
