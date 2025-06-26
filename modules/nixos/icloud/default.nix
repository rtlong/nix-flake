# NOTE: unfortunately this does not support accounts that have ADP enabled
{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.icloud;

  configYAML = pkgs.writeText "icloud-docker-conf.yaml" (
    lib.generators.toYAML { } {
      app = {
        logger = {
          # level - debug, info (default), warning or error
          level = "debug";
          # log filename icloud.log (default)
          filename = "/dev/stdout";
        };
        credentials = {
          # iCloud drive username
          username = cfg.icloudUsername;
          # Retry login interval - default is 10 minutes, specifying -1 will retry login only once and exit
          retry_login_interval = 60;
        };
        # Drive destination
        root = "/icloud";
        # discord = {
        #   # webhook_url: <your server webhook URL here>
        #   # username: icloud-docker #or any other name you prefer
        # };
        # telegram = {
        #   # bot_token: <your Telegram bot token>
        #   # chat_id: <your Telegram user or chat ID>
        # };
        # pushover = {
        #   # user_key: <your Pushover user key>
        #   # api_token: <your Pushover api token>
        # };
        # smtp = {
        #   ## If you want to receive email notifications about expired/missing 2FA credentials then uncomment
        #   # email: "user@test.com"
        #   ## optional, to email address. Default is sender email.
        #   # to: "receiver@test.com"
        #   # password:
        #   # host: "smtp.test.com"
        #   # port: 587
        #   # If your email provider doesn't handle TLS
        #   # no_tls: true
        # };
        # region = "global"; # For China server users, set this to - china (default: global)
      };
      drive = {
        destination = "drive";
        # Remove local files that are not present on server (i.e. files delete on server)
        remove_obsolete = false;
        sync_interval = 300;
        filters = {
          # Optional - use it only if you want to download specific folders.
          # File filters to be included in syncing iCloud drive content
          # folders = [
          #   "folder1"
          #   "folder2"
          #   "folder3"
          # ];
          # file_extensions = [
          #   # File extensions to be included
          #   "pdf"
          #   "png"
          #   "jpg"
          #   "jpeg"
          # ];
        };
        # ignore = [
        #   # When specifying folder paths, append it with /*
        #   "node_modules/*"
        #   "*.md"
        # ];
      };
      photos = {
        destination = "photos";
        # Remove local photos that are not present on server (i.e. photos delete on server)
        remove_obsolete = false;
        sync_interval = 500;
        all_albums = false; # Optional, default false. If true preserve album structure. If same photo is in multiple albums creates duplicates on filesystem
        folder_format = "%Y/%m/%d"; # optional, if set put photos in subfolders according to format. Format cheatsheet - https://strftime.org
        # filters = {
        #   # List of libraries to download. If omitted (default), photos from all libraries (own and shared) are downloaded. If included, photos only
        #   # from the listed libraries are downloaded.
        #   # libraries = [
        #   #   "PrimarySync" # Name of the own library
        #   # ];
        #   # if all_albums is false - albums list is used as filter-in, if all_albums is true - albums list is used as filter-out
        #   # if albums list is empty and all_albums is false download all photos to "all" folder. if empty and all_albums is true download all folders
        #   albums = [
        #     "album 1"
        #     "album2"
        #   ];
        #   file_sizes = [
        #     "original"
        #     # "medium"
        #     # "thumb"
        #   ]; # valid values are original, medium and/or thumb
        #   extensions = [
        #     # Optional, media extensions to be included in syncing iCloud Photos content
        #     # "jpg"
        #     # "heic"
        #     # "png"
        #   ];
        # };
      };
    }
  );

in
{
  options.${namespace}.icloud = {
    enable = mkBoolOpt false "Whether or not to enable the iCloud download-only sync service.";
    icloudUsername = mkOpt types.str null "Email used to login to iCloud";
  };

  config = mkIf cfg.enable {
    systemd.services.init-my-container-config = {
      wantedBy = [ "multi-user.target" ];
      before = [ "podman-icloud-downloader.service" ]; # key line
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "init-icloud-downloader" ''
          mkdir -p /var/lib/icloud-downloader
          install -m 0644 ${configYAML} \
            /var/lib/icloud-downloader/conf.yaml
        '';
      };
    };

    virtualisation.oci-containers.containers.icloud-downloader = {
      image = "docker.io/rtlong/icloud-docker";
      environment = {
        PUID = toString config.users.users.ryan.uid;
        PGID = toString config.users.groups.${config.users.users.ryan.group}.gid;
        ENV_CONFIG_FILE_PATH = "/config/conf.yaml";
      };
      volumes = [
        # "/etc/timezone:/etc/timezone:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/tank/import/icloud:/icloud"
        "/var/lib/icloud-downloader:/config" # Must contain config.yaml
        "icloud-downloader-keyring:/app/.local/share/python_keyring"
      ];
    };
  };
}
