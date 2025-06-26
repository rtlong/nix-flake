app:
  logger:
    # level - debug, info (default), warning or error
    level: "info"
    # log filename icloud.log (default)
    filename: "/config/icloud.log"
  credentials:
    # iCloud drive username
    username: "please@replace.me"
    # Retry login interval - default is 10 minutes, specifying -1 will retry login only once and exit
    retry_login_interval: 600
  # Drive destination
  root: "/icloud"
discord:
# webhook_url: <your server webhook URL here>
  # username: icloud-docker #or any other name you prefer
  telegram:
  # bot_token: <your Telegram bot token>
  # chat_id: <your Telegram user or chat ID>
  pushover:
  # user_key: <your Pushover user key>
  # api_token: <your Pushover api token>
  smtp:
    ## If you want to receive email notifications about expired/missing 2FA credentials then uncomment
    # email: "user@test.com"
    ## optional, to email address. Default is sender email.
    # to: "receiver@test.com"
    # password:
    # host: "smtp.test.com"
    # port: 587
    # If your email provider doesn't handle TLS
    # no_tls: true
  region: global # For China server users, set this to - china (default: global)
drive:
  destination: "drive"
  # Remove local files that are not present on server (i.e. files delete on server)
  remove_obsolete: false
  sync_interval: 300
  filters: # Optional - use it only if you want to download specific folders.
    # File filters to be included in syncing iCloud drive content
    folders:
      - "folder1"
      - "folder2"
      - "folder3"
    file_extensions:
      # File extensions to be included
      - "pdf"
      - "png"
      - "jpg"
      - "jpeg"
  ignore:
    # When specifying folder paths, append it with /*
    - "node_modules/*"
    - "*.md"
photos:
  destination: "photos"
  # Remove local photos that are not present on server (i.e. photos delete on server)
  remove_obsolete: false
  sync_interval: 500
  all_albums: false # Optional, default false. If true preserve album structure. If same photo is in multiple albums creates duplicates on filesystem
  folder_format: "%Y/%m" # optional, if set put photos in subfolders according to format. Format cheatsheet - https://strftime.org
  filters:
    # List of libraries to download. If omitted (default), photos from all libraries (own and shared) are downloaded. If included, photos only
    # from the listed libraries are downloaded.
    # libraries:
    #   - PrimarySync # Name of the own library

    # if all_albums is false - albums list is used as filter-in, if all_albums is true - albums list is used as filter-out
    # if albums list is empty and all_albums is false download all photos to "all" folder. if empty and all_albums is true download all folders
    albums:
      - "album 1"
      - "album2"
    file_sizes: # valid values are original, medium and/or thumb
      - "original"
      # - "medium"
      # - "thumb"
    extensions: # Optional, media extensions to be included in syncing iCloud Photos content
      # - jpg
      # - heic
      # - png/
