# WIP; this failed when last I tried (2025 Aug 18) due to a compilation error when building boost as a dependency of mongodb
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

  cfg = config.${namespace}.librechat;
in
{
  options.${namespace}.librechat = {
    enable = mkBoolOpt false "Whether or not to enable librechat";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # librechat
      mongodb
    ];

    launchd.agents.mongodb = {
      enable = true;
      config = {
        WorkingDirectory = "${config.xdg.dataHome}/librechat/";
        StandardErrorPath = "${config.xdg.dataHome}/librechat/mongo-error.log";
        StandardOutPath = "${config.xdg.dataHome}/librechat/mongo-out.log";
        Program = "${pkgs.mongodb}/bin/mongod";
        ProgramArguments = [
          "--port"
          "12345"
          "--dbpath"
          "${config.xdg.dataHome}/librechat/mongodb-data"
        ];
        EnvironmentVariables = {
        };
      };
    };

    launchd.agents.librechat = {
      enable = true;
      config = {
        WorkingDirectory = "${config.xdg.dataHome}/librechat/";
        StandardErrorPath = "${config.xdg.dataHome}/librechat/error.log";
        StandardOutPath = "${config.xdg.dataHome}/librechat/out.log";
        Program = "${pkgs.librechat}/bin/librechat-server";
        EnvironmentVariables = {
          MONGO_URI = "mongodb://localhost:12345";
        };
      };
    };
  };

}
