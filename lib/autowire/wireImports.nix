folder:
  with builtins;
  {
    imports = (import ./gatherImports.nix) folder;
  }
