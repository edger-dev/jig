# mkWorkspace — composable dev environment builder
#
# Usage (in consumer's flake.nix):
#
#   inputs.jig.url = "github:edger-dev/jig";
#
#   outputs = { self, jig }:
#     jig.lib.mkWorkspace
#       {
#         pname = "my-project";
#         src = ./.;
#         extraDevPackages = pkgs: [ ];
#       }
#       {
#         rust = { buildPackages = [ "my-cli" ]; };
#         docs = { beans = true; };
#       };
#
# First arg (config):
#   pname            — project name (required)
#   src              — source path, typically ./. (required for rust jig)
#   extraDevPackages — function: pkgs -> [packages] for devShell (default: none)
#
# Second arg (jigs):
#   rust             — Rust workspace (crane + fenix + bacon)
#   docs             — Documentation (mdbook + optional mdbook-beans)

{ nixpkgs, flake-utils, crane, fenix, mdbook-beans, jigSrc }:

config: jigs:

let
  hasRust = jigs ? rust;
  hasDocs = jigs ? docs;

  rustJig = import ./jigs/rust {
    inherit nixpkgs crane fenix;
  };

  docsJig = import ./jigs/docs {
    inherit nixpkgs mdbook-beans;
  };
in

flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};

    pname = config.pname;
    src = config.src or null;
    extraDevPackages = config.extraDevPackages or (_: []);

    # Evaluate active jigs
    rustResult = if hasRust then rustJig {
      inherit pname src system;
      jigConfig = jigs.rust;
    } else null;

    docsResult = if hasDocs then docsJig {
      inherit system;
      jigConfig = jigs.docs;
    } else null;

    # Merge packages from all jigs
    packages =
      (if rustResult != null then rustResult.packages else {})
    ;

    # Merge checks from all jigs
    checks =
      (if rustResult != null then rustResult.checks else {})
    ;

    # Merge devShell packages from all jigs
    devPackages =
      [ pkgs.mise ]
      ++ (if rustResult != null then rustResult.devPackages else [])
      ++ (if docsResult != null then docsResult.devPackages else [])
      ++ (extraDevPackages pkgs)
    ;

    # Symlink jig skills into .claude/skills/ on shell entry
    jigSkillsHook = ''
      if [ -d .claude ]; then
        mkdir -p .claude/skills
        for skill_dir in ${jigSrc}/skills/*/; do
          name="$(basename "$skill_dir")"
          target=".claude/skills/$name"
          if [ ! -e "$target" ]; then
            ln -s "$skill_dir" "$target"
          fi
        done
      fi
    '';

    # Use crane devShell if rust jig is active (inherits check environment),
    # otherwise use a plain mkShell
    devShell =
      if rustResult != null then
        rustResult.mkDevShell {
          inherit checks;
          packages = devPackages;
          shellHook = jigSkillsHook;
        }
      else
        pkgs.mkShell {
          buildInputs = devPackages;
          shellHook = jigSkillsHook;
        };
  in
  {
    inherit packages checks;
    devShells.default = devShell;
  })
