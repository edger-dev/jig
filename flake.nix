{
  description = "Nix flake modules and Claude Code skills for consistent dev environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane, fenix }:
  let
    lib = nixpkgs.lib;

    # Autowire helpers (raw imports)
    gatherNames = import ./lib/autowire/gatherNames.nix;
    gatherFiles = import ./lib/autowire/gatherFiles.nix;
    gatherExecutables = import ./lib/autowire/gatherExecutables.nix;
    gatherScriptPackages = import ./lib/autowire/gatherScriptPackages.nix;
    gatherContents = import ./lib/autowire/gatherContents.nix;
    concatContents = import ./lib/autowire/concatContents.nix;
  in
  {
    lib = {
      # Rust workspace builder
      mkRustWorkspace = import ./rust/mk-workspace.nix {
        inherit nixpkgs flake-utils crane fenix;
      };

      # Autowire: core
      autowireDefault = import ./lib/autowire/default.nix;
      doPrefixName = import ./lib/autowire/doPrefixName.nix;
      gatherImports = import ./lib/autowire/gatherImports.nix;

      # Autowire: generic (pass your own lib + suffix)
      inherit gatherNames gatherFiles gatherContents gatherExecutables gatherScriptPackages concatContents;

      # Autowire: pre-applied with nixpkgs lib
      gatherNames_ = gatherNames lib;
      gatherFiles_ = gatherFiles lib;
      gatherContents_ = gatherContents lib;
      gatherExecutables_ = gatherExecutables lib;
      gatherScriptPackages_ = gatherScriptPackages lib;

      # Autowire: fish
      gatherFiles_fish = gatherFiles lib ".fish";
      gatherExecutables_fish = gatherExecutables lib ".fish";
      gatherScriptPackages_fish = gatherScriptPackages lib ".fish";
      gatherContents_fish = gatherContents lib ".fish";
      concatContents_fish = concatContents lib ".fish" "#" "\n\n\n";

      # Autowire: bash
      gatherFiles_bash = gatherFiles lib ".bash";
      gatherExecutables_bash = gatherExecutables lib ".bash";
      gatherScriptPackages_bash = gatherScriptPackages lib ".bash";
      gatherContents_bash = gatherContents lib ".bash";
      concatContents_bash = concatContents lib ".bash" "#" "\n\n\n";

      # Autowire: nu
      gatherFiles_nu = gatherFiles lib ".nu";
      gatherExecutables_nu = gatherExecutables lib ".nu";
      gatherContents_nu = gatherContents lib ".nu";
      concatContents_nu = concatContents lib ".nu" "#" "\n\n\n";

      # Autowire: kdl
      gatherFiles_kdl = gatherFiles lib ".kdl";
      gatherContents_kdl = gatherContents lib ".kdl";
      concatContents_kdl = concatContents lib ".kdl" "//" "\n\n\n";

      # Autowire: wasm
      gatherFiles_wasm = gatherFiles lib ".wasm";
    };
  };
}
