# disko-config.nix — Encrypted eMMC root, SSD-based encrypted swap, ZFS pool (datasets managed manually)
{ lib, ... }:
{
  disko.devices = {
    # These are the NVME devices in this system:
    # - SLOT1: 3.7T Lexar SSD NM790 4TB QB4263W100817P220J /dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB4263W100817P220J (mirror A)
    # - SLOT2: 3.7T Lexar SSD NM790 4TB QB4263W101865P220J /dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB4263W101865P220J (mirror B)
    # - SLOT3: 3.7T Lexar SSD NM790 4TB QB6866W100062P220J /dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB6866W100062P220J (mirror C)
    # - SLOT4: 3.6T FIKWOT    FN955 4TB AA251730044	 /dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251730044 (mirror A) -- s/n: FN95564MA251703744
    # - SLOT5: 3.6T FIKWOT    FN955 4TB AA251740100	 /dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251740100 (mirror B) -- s/n: FN95564MA251703685
    # - SLOT6: 3.6T FIKWOT    FN955 4TB AA251730134	 /dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251730134 (mirror C) -- s/n: FN95564MA251703651
    # NOTE: the FIKWOT drives don't report the printed serial to lsblk, so I
    #   list these in order with the assumption that they are assigned device
    #   numbers in the same order that they are numbered physically. So the
    #   SLOT# and the appended s/n are the physical observations and the details
    #   in between are from lsblk sorted by device name (nvme4n1 corresponds to
    #   SLOT5)
    disk = {
      nvme0 = {
        device = "/dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB4263W100817P220J";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # mountpoint = "/boot/efi";
              };
            };
            swap = {
              size = "100%";
              label = "swap1"; # this device arbitrarily chosen for backup swap
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            zfs = {
              size = "3722G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      nvme1 = {
        device = "/dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB4263W101865P220J";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # mountpoint = "/boot/efi";
              };
            };
            reserved = {
              size = "100%";
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
              content = null;
            };
            zfs = {
              size = "3722G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      nvme2 = {
        device = "/dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_QB6866W100062P220J";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # mountpoint = "/boot/efi";
              };
            };
            reserved = {
              size = "100%";
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
              content = null;
            };
            zfs = {
              size = "3722G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      nvme3 = {
        # SLOT4 is the sole PCIe Gen 3.0x2. Seems most ideal for primary swap
        device = "/dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251730044";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
              };
            };
            swap = {
              size = "100%";
              label = "swap0"; # this is primary since it is the fastest drive
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            zfs = {
              size = "3722G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      nvme4 = {
        device = "/dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251740100";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # mountpoint = "/boot/efi";
              };
            };
            reserved = {
              size = "100%";
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
              content = null;
            };
            zfs = {
              size = "3722G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      nvme5 = {
        device = "/dev/disk/by-id/nvme-FIKWOT_FN955_4TB_AA251730134";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # mountpoint = "/boot/efi";
              };
            };
            reserved = {
              size = "100%";
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
              content = null;
            };
            zfs = {
              size = "3722G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };

    zpool.tank = {
      type = "zpool";
      mode = "raidz2";
      rootFsOptions = {
        compression = "lz4";
        xattr = "sa";
        acltype = "posixacl";
        normalization = "formD";
        atime = "off";
      };
      mountpoint = null;
      postCreateHook = ''
        zfs set mountpoint=none tank
      '';
    };
  };
}
