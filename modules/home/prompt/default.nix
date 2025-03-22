{
  config,
  namespace,
  pkgs,
  lib,
  ...
}:

let
  toml = pkgs.formats.toml { };

  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  defaultSettings = {
    shlvl = {
      disabled = false;
      threshold = 0;
    };

    directory = {
      truncation_length = 10;
      truncate_to_repo = false; # truncates directory to root folder if in github repo
      # truncation_symbol = "…/";
      # fish_style_pwd_dir_length = 1;
      # read_only = " ";
      # style = "bold bright-blue";
      # repo_root_style = "bold bright-green";
      # repo_root_format = "[$before_root_path]($style)[$repo_root$path]($repo_root_style)[$read_only]($read_only_style) ";

      substitutions = {
        "~/Code/github.com/" = " ";
      };
    };
  };

  defaultSettingsSimple = {
    # format = "$directory$character";
    format = "$character";

    directory.style = "blue";

    character = {
      success_symbol = "[>](green)";
      error_symbol = "[x](red)";
    };
  };

  cfg = config.${namespace}.prompt;
in
{
  options.${namespace}.prompt = {
    enable = mkBoolOpt true "Enable starship prompt";
    config = mkOption {
      type = types.attrsOf types.anything;
      default = defaultSettings;
      description = "Settings for starship to be written as the starship.toml file";
    };
    simpleConfig = mkOption {
      type = types.attrsOf types.anything;
      default = defaultSettingsSimple;
      description = "Settings for starship to be written as the starship_simple.toml file";
    };
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = cfg.config;
    };

    # define another file with a simpler prompt for use in embedded terminals (eg. in IDE)
    xdg.configFile."starship_simple.toml".source = toml.generate "starship_simple.toml" cfg.simpleConfig;
  };
}
