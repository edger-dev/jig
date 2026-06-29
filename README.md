# jig

Nix flake modules and Claude Code skills for consistent dev environments across projects.

## Jigs

Each jig is an independent, composable module:

| Jig | What it provides |
|-----|-----------------|
| **rust** | Crane + fenix build, clippy/fmt checks, bacon diagnostics, mise tasks, TDD workflow |
| **docs** | mdbook setup, mise tasks |
| **kinora** | Knowledge ledger (specs/tasks/plans in `.kinora/`), the `kinora` CLI on PATH, engineering-workflow CLAUDE.md |

## Usage

### Nix Flake

```nix
{
  inputs.jig.url = "github:edger-dev/jig";

  outputs = { self, jig }:
    jig.lib.mkWorkspace
      {
        pname = "my-project";
        src = ./.;
        # extraDevPackages = pkgs: [ ];
      }
      {
        rust = {
          # buildPackages = [ "my-cli" ];
          # wasm = true;
        };
        docs = {};
        kinora = {};   # puts the `kinora` CLI on the devShell PATH
      };
}
```

Update toolchain/packages: `nix flake update jig`

### Claude Code Skill

Copy `skills/jig.md` into your project's `.claude/skills/` (or your global `~/.claude/skills/`), then:

```
/jig init rust        # scaffold rust workspace config
/jig init docs        # scaffold mdbook documentation
/jig init kinora      # scaffold the kinora knowledge ledger
/jig sync             # update jig-managed files from latest templates
/jig list             # show active jigs
```

## Structure

```
flake.nix                       # exports lib.mkWorkspace, lib.autowire
mk-workspace.nix                # composable workspace builder
jigs/
  rust/default.nix              # rust jig (crane + fenix + bacon)
  docs/default.nix              # docs jig (mdbook)
  kinora/default.nix            # kinora jig (builds the kinora CLI via crane)
lib/
  autowire/                     # nix module/file autowiring helpers
templates/
  rust/                         # rust jig templates
  docs/                         # docs jig templates
  kinora/                       # kinora jig templates (CLAUDE.md + config.styx)
skills/
  jig.md                        # Claude Code skill definition
```
