lib: suffix: pkgs: folder:
let
  gatherContents = (import ./gatherContents.nix) lib;
  contents = gatherContents suffix folder;
in
  builtins.map
  ({ name, value }: pkgs.writeShellScriptBin name value)
  (lib.attrsToList contents)
