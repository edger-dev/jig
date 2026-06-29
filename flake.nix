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
    # kinora CLI source, built from pinned source via crane by the kinora jig.
    # `flake = false` keeps this acyclic: jig never evaluates kinora's flake
    # (which itself depends on jig) — it only consumes the source tree.
    kinora-src = {
      url = "github:edger-dev/kinora";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane, fenix, kinora-src }: {
    lib = {
      mkWorkspace = import ./mk-workspace.nix {
        inherit nixpkgs flake-utils crane fenix kinora-src;
        jigSrc = self;
      };

      autowire = import ./lib/autowire { lib = nixpkgs.lib; };
    };

    # Nix store path to jig skills — works for both local and git flake inputs
    skillsPath = self + "/skills";
  };
}
