{ lib }:

let
  gatherNames = import ./gatherNames.nix;
  gatherFiles = import ./gatherFiles.nix;
  gatherExecutables = import ./gatherExecutables.nix;
  gatherScriptPackages = import ./gatherScriptPackages.nix;
  gatherContents = import ./gatherContents.nix;
  concatContents = import ./concatContents.nix;
in
{
  # Core
  wireImports = import ./wireImports.nix;
  doPrefixName = import ./doPrefixName.nix;
  gatherImports = import ./gatherImports.nix;

  # Generic (pass your own suffix)
  inherit gatherNames gatherFiles gatherContents gatherExecutables gatherScriptPackages concatContents;

  # Pre-applied with nixpkgs lib
  gatherNames_ = gatherNames lib;
  gatherFiles_ = gatherFiles lib;
  gatherContents_ = gatherContents lib;
  gatherExecutables_ = gatherExecutables lib;
  gatherScriptPackages_ = gatherScriptPackages lib;

  # Fish
  gatherFiles_fish = gatherFiles lib ".fish";
  gatherExecutables_fish = gatherExecutables lib ".fish";
  gatherScriptPackages_fish = gatherScriptPackages lib ".fish";
  gatherContents_fish = gatherContents lib ".fish";
  concatContents_fish = concatContents lib ".fish" "#" "\n\n\n";

  # Bash
  gatherFiles_bash = gatherFiles lib ".bash";
  gatherExecutables_bash = gatherExecutables lib ".bash";
  gatherScriptPackages_bash = gatherScriptPackages lib ".bash";
  gatherContents_bash = gatherContents lib ".bash";
  concatContents_bash = concatContents lib ".bash" "#" "\n\n\n";

  # Nu
  gatherFiles_nu = gatherFiles lib ".nu";
  gatherExecutables_nu = gatherExecutables lib ".nu";
  gatherContents_nu = gatherContents lib ".nu";
  concatContents_nu = concatContents lib ".nu" "#" "\n\n\n";

  # KDL
  gatherFiles_kdl = gatherFiles lib ".kdl";
  gatherContents_kdl = gatherContents lib ".kdl";
  concatContents_kdl = concatContents lib ".kdl" "//" "\n\n\n";

  # WASM
  gatherFiles_wasm = gatherFiles lib ".wasm";
}
