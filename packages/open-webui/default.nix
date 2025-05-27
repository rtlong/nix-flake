{
  config,
  lib,
  pkgs,
  ...
}:

(pkgs.writeShellApplication {
  name = "open-webui";
  text = ''
    set -x
    export DATA_DIR="$HOME/.open-webui"
    export UV_NO_MANAGED_PYTHON=true
    export UV_PYTHON="${pkgs.python311}"
    cd "$DATA_DIR"
    exec ${pkgs.uv}/bin/uvx open-webui@latest serve "$@"
  '';
})
