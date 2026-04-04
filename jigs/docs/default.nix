# Docs jig — mdbook + optional mdbook-beans
#
# Returns: { devPackages }

{ nixpkgs, mdbook-beans }:

{ system, jigConfig }:

let
  pkgs = nixpkgs.legacyPackages.${system};
  withBeans = jigConfig.beans or false;
in
{
  devPackages =
    [ pkgs.mdbook ]
    ++ pkgs.lib.optionals withBeans [
      mdbook-beans.packages.${system}.default
    ];
}
