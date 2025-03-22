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
  inherit (lib.${namespace}) enabled mkBoolOpt;

  cfg = config.${namespace}.nexa;

  # CMAKE_ARGS="-DGGML_METAL=ON -DSD_METAL=ON" pip install nexaai --prefer-binary --index-url https://github.nexa.ai/whl/metal --extra-index-url https://pypi.org/simple --no-cache-dir

  package = pkgs.buildPythonPackage rec {
    pname = "nexaai";
    version = "0.0.9.6";
    format = "wheel";

    src = pkgs.fetchPypi {
      inherit pname version;
      sha256 = ""; # Replace with the actual SHA256 hash
    };

    # Add any build inputs required by the package
    buildInputs = [
      # Add dependencies here
    ];

    # Add any propagated build inputs (runtime dependencies)
    propagatedBuildInputs = [
      # Add dependencies here
    ];

    # Add any additional build arguments
    buildPhase = ''
      # Add custom build steps here if needed
    '';

    # Disable tests if necessary
    doCheck = false;

    # Add any post-installation steps if required
    postInstall = ''
      # Add post-installation steps here
    '';
  };

in
{
  options.${namespace}.nexa = {
    enable = mkBoolOpt false "Whether or not to enable Nexa SDK";
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    launchd.agents.nexa-sdk = {
      enable = true;
      config = {
        StandardOutPath = "/tmp/nexa.log";
        StandardErrorPath = "/tmp/nexa.log";
        ProgramArguments = [
          "${package}/bin/nexa"
          "-V"
        ];
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };
}
