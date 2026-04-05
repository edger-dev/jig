{ lib }:

let
  gatherNames_ = import ./gatherNames.nix;
  gatherFiles_ = import ./gatherFiles.nix;
  gatherExecutables_ = import ./gatherExecutables.nix;
  gatherScriptPackages_ = import ./gatherScriptPackages.nix;
  gatherContents_ = import ./gatherContents.nix;
  concatContents_ = import ./concatContents.nix;
in
{
  # Core
  wireImports = import ./wireImports.nix;
  wireImportsRecursively = import ./wireImportsRecursively.nix;
  doPrefixName = import ./doPrefixName.nix;
  gatherImports = import ./gatherImports.nix;
  gatherImportsRecursively = import ./gatherImportsRecursively.nix;

  # Raw (pass lib and your own suffix)
  inherit gatherNames_ gatherFiles_ gatherContents_ gatherExecutables_ gatherScriptPackages_ concatContents_;

  # Pre-applied with nixpkgs lib (pass your own suffix)
  gatherNames = gatherNames_ lib;
  gatherFiles = gatherFiles_ lib;
  gatherContents = gatherContents_ lib;
  gatherExecutables = gatherExecutables_ lib;
  gatherScriptPackages = gatherScriptPackages_ lib;

  # Fish
  gatherFiles_fish = gatherFiles_ lib ".fish";
  gatherExecutables_fish = gatherExecutables_ lib ".fish";
  gatherScriptPackages_fish = gatherScriptPackages_ lib ".fish";
  gatherContents_fish = gatherContents_ lib ".fish";
  concatContents_fish = concatContents_ lib ".fish" "#" "\n\n\n";

  # Bash
  gatherFiles_bash = gatherFiles_ lib ".bash";
  gatherExecutables_bash = gatherExecutables_ lib ".bash";
  gatherScriptPackages_bash = gatherScriptPackages_ lib ".bash";
  gatherContents_bash = gatherContents_ lib ".bash";
  concatContents_bash = concatContents_ lib ".bash" "#" "\n\n\n";

  # Nu
  gatherFiles_nu = gatherFiles_ lib ".nu";
  gatherExecutables_nu = gatherExecutables_ lib ".nu";
  gatherContents_nu = gatherContents_ lib ".nu";
  concatContents_nu = concatContents_ lib ".nu" "#" "\n\n\n";

  # KDL
  gatherFiles_kdl = gatherFiles_ lib ".kdl";
  gatherContents_kdl = gatherContents_ lib ".kdl";
  concatContents_kdl = concatContents_ lib ".kdl" "//" "\n\n\n";

  # WASM
  gatherFiles_wasm = gatherFiles_ lib ".wasm";
}
