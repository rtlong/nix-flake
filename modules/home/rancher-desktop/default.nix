{
  namespace,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.${namespace}.rancher-desktop;
in
{
  options = {
    ${namespace}.rancher-desktop = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Rancher Desktop support (install Rancher Desktop separately!)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Add Rancher Desktop to the PATH
    programs.zsh.envExtra = ''
      export PATH="$HOME/.rd/bin:$PATH"
    '';
  };
}
