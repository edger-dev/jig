# Docs jig — mdbook
#
# Returns: { devPackages }
#
# Note: kinora needs no mdbook preprocessor — `kinora render` builds its own
# mdbook from the ledger. Enable the `kinora` jig to get the `kinora` CLI.

{ nixpkgs }:

{ system, jigConfig }:

let
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  devPackages = [ pkgs.mdbook ];
}
