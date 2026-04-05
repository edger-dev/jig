folder:
  with builtins;
  {
    imports = (import ./gatherImportsRecursively.nix) folder;
  }
