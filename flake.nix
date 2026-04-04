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
    mdbook-beans = {
      url = "github:edger-dev/mdbook-beans/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.crane.follows = "crane";
      inputs.fenix.follows = "fenix";
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane, fenix, mdbook-beans }: {
    lib = {
      mkWorkspace = import ./mk-workspace.nix {
        inherit nixpkgs flake-utils crane fenix mdbook-beans;
        jigSrc = self;
      };

      autowire = import ./lib/autowire { lib = nixpkgs.lib; };
    };

    # Nix store path to jig skills — works for both local and git flake inputs
    skillsPath = self + "/skills";
  };
}
