lib: suffix: folder:
let
  gatherFiles = import ./gatherFiles.nix;
in
lib.mapAttrs'
(name: value:
{
  name = lib.removeSuffix suffix name;
  value = value // {
    executable = true;
  };
})
(gatherFiles lib suffix folder)
