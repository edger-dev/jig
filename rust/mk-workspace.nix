# mkRustWorkspace — opinionated Rust dev environment builder
#
# Usage (in consumer's flake.nix):
#
#   inputs.jig.url = "github:edger-dev/jig";
#
#   outputs = { self, jig }:
#     jig.lib.mkRustWorkspace {
#       pname = "my-project";
#       src = ./.;
#     };
#
# Options:
#   pname            — project name (required)
#   src              — source path, typically ./. (required)
#   buildPackages    — list of crate names to build (default: whole workspace)
#   wasm             — include wasm32-unknown-unknown target (default: false)
#   extraDevPackages — function: pkgs -> [packages] for devShell (default: none)
#   extraChecks      — function: { craneLib, commonArgs, cargoArtifacts } -> attrset (default: none)

{ nixpkgs, flake-utils, crane, fenix }:

{ pname
, src
, buildPackages ? []
, wasm ? false
, extraDevPackages ? (_: [])
, extraChecks ? (_: {})
}:

flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};

    toolchain = fenix.packages.${system}.combine ([
      fenix.packages.${system}.stable.rustc
      fenix.packages.${system}.stable.cargo
      fenix.packages.${system}.stable.clippy
      fenix.packages.${system}.stable.rustfmt
    ] ++ pkgs.lib.optionals wasm [
      fenix.packages.${system}.targets.wasm32-unknown-unknown.stable.rust-std
    ]);

    craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;
    cleanSrc = craneLib.cleanCargoSource src;

    cargoExtraArgs =
      if buildPackages != []
      then builtins.concatStringsSep " " (map (p: "--package ${p}") buildPackages)
      else "";

    commonArgs = {
      src = cleanSrc;
      inherit pname;
      strictDeps = true;
    } // pkgs.lib.optionalAttrs (cargoExtraArgs != "") {
      inherit cargoExtraArgs;
    };

    cargoArtifacts = craneLib.buildDepsOnly commonArgs;

    package = craneLib.buildPackage (commonArgs // {
      inherit cargoArtifacts;
    });

    clippy = craneLib.cargoClippy (commonArgs // {
      inherit cargoArtifacts;
      cargoClippyExtraArgs =
        (if cargoExtraArgs != "" then cargoExtraArgs else "--all-targets")
        + " -- --deny warnings";
    });

    fmt = craneLib.cargoFmt { inherit pname; src = cleanSrc; };

    checks = {
      build = package;
      inherit clippy fmt;
    } // (extraChecks { inherit craneLib commonArgs cargoArtifacts; });
  in
  {
    packages = {
      ${pname} = package;
      default = package;
    };

    inherit checks;

    devShells.default = craneLib.devShell {
      inherit checks;
      packages = [
        pkgs.sccache
        pkgs.mise
        pkgs.bacon
      ] ++ (extraDevPackages pkgs);
    };
  })
