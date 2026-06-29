# Kinora jig — provides the `kinora` CLI, built from pinned source via crane
#
# Returns: { devPackages }
#
# kinora is the knowledge ledger: engineering intent (specs/tasks/plans) lives
# in `.kinora/`, version-controlled alongside the code. This jig puts the
# `kinora` binary on the devShell PATH. The ledger itself is scaffolded from
# `templates/kinora/` by `/jig init kinora`.

{ nixpkgs, crane, fenix, kinora-src }:

{ system, jigConfig }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  toolchain = fenix.packages.${system}.combine [
    fenix.packages.${system}.stable.rustc
    fenix.packages.${system}.stable.cargo
  ];

  craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

  kinora = craneLib.buildPackage {
    pname = "kinora";
    version = "0.0.1";
    src = craneLib.cleanCargoSource kinora-src;
    # The workspace ships several crates; we only need the CLI binary.
    cargoExtraArgs = "--package kinora-cli";
    strictDeps = true;
    doCheck = false;
  };
in
{
  devPackages = [ kinora ];
}
