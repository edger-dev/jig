lib: suffix: commentMarker: sep: folder:
let
  gatherContents = import ./gatherContents.nix;
  withComments =
    lib.map
    ({ name, value }:
      "\n${commentMarker} /* autowire ------------ ${name}.${suffix} ------------\n" +
      value +
      "\n${commentMarker} */ autowire ------------ ${name}.${suffix} ------------\n"
    )
    (lib.attrsToList (gatherContents lib suffix folder));
in
  builtins.concatStringsSep sep withComments
