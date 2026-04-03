lib: suffix: folder:
let
  names =
    lib.filterAttrs
    (name: type:
      type == "regular"
        && lib.hasSuffix suffix name
        && !lib.hasSuffix ".nix" name)
    (builtins.readDir folder);
in
  builtins.attrNames names
