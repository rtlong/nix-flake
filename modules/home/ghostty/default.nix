{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace,
  # The namespace used for your flake, defaulting to "internal" if not set.
  system,
  # The home architecture for this host (eg. `x86_64-linux`).
  target,
  # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format,
  # A normalized name for the home target (eg. `home`).
  virtual,
  # A boolean to determine whether this home is a virtual target using nixos-generators.
  host, # The host name for this home.

  # All other arguments come from the home home.
  config,
  ...
}:
let
  inherit (builtins) map listToAttrs;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt mkOpt;

  cfg = config.${namespace}.ghostty;
  install = !(lib.snowfall.system.is-darwin system);
in
{
  options.${namespace}.ghostty = {
    enable = mkBoolOpt true "Whether or not to enable ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    ${namespace}.skhd.appLaunchBinds.T = "Ghostty";

    programs.ghostty = {
      enable = cfg.enable;
      package = if install then pkgs.ghostty else null;
      settings = {
        # https://ghostty.org/docs/config/reference
        theme = "rtlong";
        font-size = 10;
        keybind = [
          "super+q=quit"

          "super+shift+w=close_window"
          "super+n=new_window"
          "super+alt+shift+w=close_all_windows"
          "super+w=close_surface"

          "global:cmd+ctrl+grave_accent=toggle_quick_terminal"

          "super+ctrl+f=toggle_fullscreen"
          "super+enter=toggle_fullscreen"

          "super+alt+w=close_tab"
          "super+physical:one=goto_tab:1"
          "super+physical:two=goto_tab:2"
          "super+physical:three=goto_tab:3"
          "super+physical:four=goto_tab:4"
          "super+physical:five=goto_tab:5"
          "super+physical:six=goto_tab:6"
          "super+physical:seven=goto_tab:7"
          "super+physical:eight=goto_tab:8"
          "super+physical:nine=last_tab"
          "ctrl+shift+tab=previous_tab"
          "super+shift+left_bracket=previous_tab"
          "super+t=new_tab"
          "ctrl+tab=next_tab"
          "super+shift+right_bracket=next_tab"

          "super+shift+d=new_split:down"
          "super+d=new_split:right"
          "super+j=goto_split:down"
          "super+h=goto_split:left"
          "super+l=goto_split:right"
          "super+k=goto_split:up"
          "super+shift+enter=toggle_split_zoom"
          "super+ctrl+down=resize_split:down,10"
          "super+ctrl+left=resize_split:left,10"
          "super+ctrl+right=resize_split:right,10"
          "super+ctrl+up=resize_split:up,10"
          "super+ctrl+equal=equalize_splits"

          "super+c=copy_to_clipboard"
          "super+v=paste_from_clipboard"
          "super+shift+v=paste_from_selection"

          "shift+down=adjust_selection:down"
          "shift+end=adjust_selection:end"
          "shift+home=adjust_selection:home"
          "shift+left=adjust_selection:left"
          "shift+page_down=adjust_selection:page_down"
          "shift+page_up=adjust_selection:page_up"
          "shift+right=adjust_selection:right"
          "shift+up=adjust_selection:up"
          "super+a=select_all"

          "super+minus=decrease_font_size:1"
          "super+equal=increase_font_size:1"
          "super+plus=increase_font_size:1"
          "super+zero=reset_font_size"

          "alt+left=esc:b"
          "alt+right=esc:f"

          "super+alt+i=inspector:toggle"

          "super+shift+up=jump_to_prompt:-1"
          "super+up=jump_to_prompt:-1"
          "super+down=jump_to_prompt:1"
          "super+shift+down=jump_to_prompt:1"

          "super+comma=open_config"
          "super+shift+comma=reload_config"

          "super+page_down=scroll_page_down"
          "super+page_up=scroll_page_up"
          "super+end=scroll_to_bottom"
          "super+home=scroll_to_top"

          "super+alt+shift+j=write_screen_file:open"
          "super+shift+j=write_screen_file:paste"

          # "super+k=clear_screen"
        ];
      };

      clearDefaultKeybinds = true;
      installBatSyntax = install;
      enableZshIntegration = true;

      themes = {
        rtlong = {
          palette = [
            "0=#45475a"
            "1=#f38ba8"
            "2=#a6e3a1"
            "3=#f9e2af"
            "4=#89b4fa"
            "5=#f5c2e7"
            "6=#94e2d5"
            "7=#bac2de"
            "8=#585b70"
            "9=#f38ba8"
            "10=#a6e3a1"
            "11=#f9e2af"
            "12=#89b4fa"
            "13=#f5c2e7"
            "14=#94e2d5"
            "15=#a6adc8"
          ];
          background = "1e1e2e";
          foreground = "cdd6f4";
          cursor-color = "f5e0dc";
          selection-background = "353749";
          selection-foreground = "cdd6f4";
        };
      };
    };
  };
}
