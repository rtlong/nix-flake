{ lib, ... }:
with lib;
rec {
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  mkOpt' = type: default: mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };

  capitalize =
    s:
    let
      len = stringLength s;
    in
    if len == 0 then "" else (lib.toUpper (substring 0 1 s)) + (substring 1 len s);

  # return an int (1/0) based on boolean value
  # `boolToNum true` -> 1
  boolToNum = bool: if bool then 1 else 0;

  default-attrs = mapAttrs (_key: mkDefault);

  force-attrs = mapAttrs (_key: mkForce);

  nested-default-attrs = mapAttrs (_key: default-attrs);

  nested-force-attrs = mapAttrs (_key: force-attrs);

  # alias because my brain does not understand this nonsense
  join = concatStringsSep;

  # right-to-left composition; compose [a b c] x == a (b (c x))
  compose = fns: v: foldr (f: e: f e) v fns;

  # (string: bool) => string => string
  filterLines =
    pred:
    compose [
      (join "\n")
      (filter pred)
      (strings.splitString "\n")
    ];

  # array => bool
  isEmpty = compose [
    (lessThan 1)
    length
  ];

  # f => f
  complement = f: v: !(f v);
}
