# Rust jig — crane + fenix + bacon + sccache
#
# Returns: { packages, checks, devPackages, mkDevShell }

{ nixpkgs, crane, fenix }:

{ pname, src, system, jigConfig }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  buildPackages = jigConfig.buildPackages or [];
  wasm = jigConfig.wasm or false;
  extraChecks = jigConfig.extraChecks or (_: {});

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

in
{
  packages = {
    ${pname} = package;
    default = package;
  };

  checks = {
    build = package;
    inherit clippy fmt;
  } // (extraChecks { inherit craneLib commonArgs cargoArtifacts; });

  devPackages = [
    pkgs.sccache
    pkgs.bacon
  ];

  # Expose crane's devShell builder so mkWorkspace can use it
  mkDevShell = { checks, packages, shellHook ? "" }: craneLib.devShell {
    inherit checks packages shellHook;
  };
}
