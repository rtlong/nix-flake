{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkForce;
in
{
  imports = [
    ../silo-1
  ];

  config = {
    fileSystems."/" = mkForce {
      device = "/dev/disk/by-uuid/38bda28e-859c-4dbd-9cbd-64bb09bdf00d";
      fsType = "ext4";
    };

    fileSystems."/boot" = mkForce {
      device = "/dev/disk/by-uuid/6875-BDD2";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    swapDevices = mkForce [ ];

    networking.hostName = mkForce "silo-1";

    users.users.root = {
      hashedPassword = mkForce null;
      initialHashedPassword = mkForce config.primaryUser.hashedPassword;
    };

  };
}
