# Snowfall Lib provides access to additional information via a primary argument of
# your overlay.
{
  # Channels are named after NixPkgs instances in your flake inputs. For example,
  # with the input `nixpkgs` there will be a channel available at `channels.nixpkgs`.
  # These channels are system-specific instances of NixPkgs that can be used to quickly
  # pull packages into your overlay.
  channels
, inputs
, lib
, ...
}:

let
  inherit (lib) lists strings debug;

  trc = label: debug.traceValFn (v: "${label}: ${toString v}");
in
final: prev: {
  # For example, to pull a package from unstable NixPkgs make sure you have the
  # input `unstable = "github:nixos/nixpkgs/nixos-unstable"` in your flake.
  # inherit (channels.unstable) chromium;

  # my-package = inputs.my-input.packages.${prev.system}.my-package;


  # inherit (channels.stable) git-with-svn;
  gitFull = prev.gitFull.overrideAttrs
    (old: {
      patches = lists.concatMap
        (patch:
          if (strings.hasInfix "gitk_check_main_window_visibility_before_waiting_for_it_to_show" patch) # this patch is already applied and errors out
          then [ ]
          else [ patch ]
        )
        old.patches;
    });
}
