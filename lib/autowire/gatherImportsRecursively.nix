# Recursively gather all .nix imports from a directory tree.
# - .nix files are imported directly
# - Subdirectories with a default.nix are imported as a single module (respecting custom wiring)
# - Subdirectories without default.nix are recursed into
# - default.nix at the root is always excluded
folder:
let
  entries = builtins.readDir folder;
  names = builtins.filter (name: name != "default.nix") (builtins.attrNames entries);
  resolve = name:
    let
      path = "${folder}/${name}";
      type = entries.${name};
    in
    if type == "directory" then
      if builtins.pathExists "${path}/default.nix" then
        [ path ]
      else
        (import ./gatherImportsRecursively.nix) path
    else if builtins.match ".*\\.nix" name != null then
      [ path ]
    else
      [];
in
builtins.concatMap resolve names
