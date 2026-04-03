lib: suffix: folder:
let
  gatherNames = import ./gatherNames.nix;
in
  builtins.listToAttrs (
    builtins.map
    (name: {
      name = lib.removeSuffix suffix name;
      value = builtins.readFile "${folder}/${name}";
    })
    (gatherNames lib suffix folder)
  )
