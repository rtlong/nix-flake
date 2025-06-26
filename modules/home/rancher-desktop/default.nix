{
  namespace,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.rancher-desktop;
in
{
  options = {
    ${namespace}.rancher-desktop = {
      enable = mkBoolOpt false "Enable Rancher Desktop support (install Rancher Desktop separately!)";
    };
  };

  config = mkIf cfg.enable {
    # Add Rancher Desktop to the PATH
    programs.zsh.envExtra = ''
      export PATH="$HOME/.rd/bin:$PATH"
    '';
  };
}
