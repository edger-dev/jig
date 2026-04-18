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

  # Onboarding scaffold — fresh workspaces often lack a Cargo.lock or a declared
  # `version`, both of which crane needs to evaluate cleanly. We patch these in
  # a Nix-store copy of src only; the user's working tree is never touched.
  cargoTomlPath = src + "/Cargo.toml";
  cargoTomlExists = builtins.pathExists cargoTomlPath;
  cargoToml =
    if cargoTomlExists
    then builtins.fromTOML (builtins.readFile cargoTomlPath)
    else {};

  workspaceMembers = (cargoToml.workspace or {}).members or null;
  isEmptyWorkspace = workspaceMembers != null && workspaceMembers == [];

  hasVersion =
    ((cargoToml.package or {}).version or null) != null ||
    (((cargoToml.workspace or {}).package or {}).version or null) != null;

  needsLock = !builtins.pathExists (src + "/Cargo.lock");
  needsVersionInject = cargoTomlExists && !hasVersion;
  needsScaffold = needsLock || needsVersionInject;

  scaffoldedSrc =
    if !needsScaffold then src
    else pkgs.runCommand "${pname}-scaffolded-src" {} ''
      cp -r ${src} $out
      chmod -R u+w $out
      ${pkgs.lib.optionalString needsLock ''
        touch $out/Cargo.lock
      ''}
      ${pkgs.lib.optionalString needsVersionInject ''
        # Silence crane's "version cannot be found" warning by injecting a
        # fallback workspace.package.version into the scaffolded Cargo.toml.
        # (A synthetic placeholder crate would require regenerating Cargo.lock,
        # which conflicts with crane's `--locked` invocation.)
        if grep -q '^\[workspace\.package\]' $out/Cargo.toml; then
          sed -i '/^\[workspace\.package\]/a version = "0.0.0"' $out/Cargo.toml
        else
          printf '\n[workspace.package]\nversion = "0.0.0"\n' >> $out/Cargo.toml
        fi
      ''}
    '';

  cleanSrc = craneLib.cleanCargoSource scaffoldedSrc;

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

  # Empty workspaces (`members = []`) have no targets for cargo fmt/clippy/build
  # to operate on, so we skip these checks during onboarding. They come back
  # automatically once the user registers their first real crate.
  rustChecks =
    if isEmptyWorkspace then {}
    else {
      build = package;
      inherit clippy fmt;
    };
  rustPackages =
    if isEmptyWorkspace then {}
    else {
      ${pname} = package;
      default = package;
    };

in
{
  packages = rustPackages;

  checks = rustChecks
    // (extraChecks { inherit craneLib commonArgs cargoArtifacts; });

  devPackages = [
    pkgs.sccache
    pkgs.bacon
  ];

  # Expose crane's devShell builder so mkWorkspace can use it
  mkDevShell = { checks, packages, shellHook ? "" }: craneLib.devShell {
    inherit checks packages shellHook;
  };
}
