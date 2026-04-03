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

  outputs = { self, nixpkgs, flake-utils, crane, fenix }: {
    lib.mkRustWorkspace = import ./rust/mk-workspace.nix {
      inherit nixpkgs flake-utils crane fenix;
    };
  };
}
