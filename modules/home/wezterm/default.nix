{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.wezterm;

  # File handler binary that processes file paths and opens them
  fileHandler = pkgs.rustPlatform.buildRustPackage {
    pname = "wezterm-file-handler";
    version = "0.1.0";

    src = ./file-handler;

    cargoLock = {
      lockFile = ./file-handler/Cargo.lock;
    };

    installPhase = ''
      mkdir -p $out/bin
      cp target/*/release/wezterm-file-handler $out/bin/
    '';
  };

  # Templated config with file handler path
  templatedConfig = pkgs.replaceVars ./config.lua {
    fileHandler = "${fileHandler}/bin/wezterm-file-handler";
  };

  # Test derivation for wezterm config
  configTest = pkgs.rustPlatform.buildRustPackage {
    pname = "wezterm-config-test";
    version = "0.1.0";

    src = ./test;

    cargoLock = {
      lockFile = ./test/Cargo.lock;
    };

    nativeBuildInputs = [ pkgs.lua ];

    # Make config.lua available to the test
    preBuild = ''
      mkdir -p ../
      cp ${./config.lua} ../config.lua

      # Validate Lua syntax (luac compiles without executing, so missing wezterm module is ok)
      echo "Checking Lua syntax..."
      luac -p ../config.lua || {
        echo "❌ Lua syntax check failed!"
        exit 1
      }
      echo "✓ Lua syntax is valid"
    '';

    # Run tests during check phase
    doCheck = true;

    # The binary itself is the test runner
    installPhase = ''
      mkdir -p $out/bin
      cp target/*/release/wezterm-config-test $out/bin/

      # Run the regex pattern tests
      $out/bin/wezterm-config-test
    '';
  };
in
{
  options.${namespace}.wezterm = {
    enable = mkBoolOpt true "Whether or not to enable wezterm.";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;

      # The config depends on tests passing - this forces configTest to build
      # (and run its tests) before the config can be used. If tests fail, the
      # entire configuration build fails, preventing invalid regex patterns.
      extraConfig =
        assert (builtins.pathExists "${configTest}/bin/wezterm-config-test");
        builtins.readFile templatedConfig;
    };
  };
}
