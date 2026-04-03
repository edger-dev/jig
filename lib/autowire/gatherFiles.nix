lib: suffix: folder:
let
  gatherNames = import ./gatherNames.nix;
  files =
    builtins.map
    (name: {
      name = name;
      value = {
        source = "${folder}/${name}";
      };
    })
    (gatherNames lib suffix folder);
in
  builtins.listToAttrs files
