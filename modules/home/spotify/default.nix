{
  lib,
  pkgs,
  inputs,
  namespace,
  system,
  config,
  ...
}:
let
  # inherit (builtins) map mapAttrs listToAttrs;
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.spotify;

in
{
  options.${namespace}.spotify = {
    enable = mkBoolOpt false "Whether or not to enable spotify.";
    package = mkOption {
      type = types.package;
      default = pkgs.spotify;
      description = "This option specifies the Spotify package to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.spicetify =
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${system};
      in
      {
        enable = true;
        enabledExtensions = with spicePkgs.extensions; [
          # official extensions -- see https://spicetify.app/docs/advanced-usage/extensions
          keyboardShortcut
          shuffle # shuffle+ (special characters are sanitized out of extension names)
          trashbin

          # community extensions below:
          # adblock # https://github.com/rxri/spicetify-extensions/blob/main/adblock/README.md
          songstats # https://github.com/rxri/spicetify-extensions/blob/main/songstats/README.md
          autoSkip # https://github.com/daksh2k/Spicetify-stuff/tree/master/Extensions/auto-skip
          betterGenres # https://github.com/Vexcited/better-spotify-genres/
          fullAppDisplayMod # https://github.com/huhridge/huh-spicetify-extensions
          fullAlbumDate # https://github.com/huhridge/huh-spicetify-extensions
          listPlaylistsWithSong # https://github.com/huhridge/huh-spicetify-extensions
          hidePodcasts # https://github.com/theRealPadster/spicetify-hide-podcasts
          skipOrPlayLikedSongs # https://github.com/Tetrax-10/Spicetify-Extensions

          savePlaylists # https://github.com/daksh2k/Spicetify-stuff/blob/master/Extensions/savePlaylists.js
          showQueueDuration # https://github.com/3raxton/spicetify-custom-apps-and-extensions/tree/main/v2/show-queue-duration
          # wikify # https://github.com/rxri/spicetify-extensions/blob/main/wikify/README.md
        ];
        theme = spicePkgs.themes.sleek;
        colorScheme = "BladeRunner";
      };
  };
}
