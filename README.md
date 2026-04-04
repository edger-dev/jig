# jig

Nix flake modules and Claude Code skills for consistent dev environments across projects.

## Jigs

Each jig is an independent, composable module:

| Jig | What it provides |
|-----|-----------------|
| **beans** | Issue tracking config, Claude Code hooks, workflow practices (planning, commits, code review) |
| **rust** | Crane + fenix build, clippy/fmt checks, bacon diagnostics, mise tasks, TDD workflow |
| **docs** | mdbook setup, optional mdbook-beans integration, mise tasks |

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
        docs = {
          # beans = true;
        };
      };
}
```

Update toolchain/packages: `nix flake update jig`

### Claude Code Skill

Copy `skills/jig.md` into your project's `.claude/skills/` (or your global `~/.claude/skills/`), then:

```
/jig init beans       # scaffold beans issue tracking
/jig init rust        # scaffold rust workspace config
/jig init docs        # scaffold mdbook documentation
/jig sync             # update jig-managed files from latest templates
/jig list             # show active jigs
```

## Structure

```
flake.nix                       # exports lib.mkWorkspace, lib.autowire
mk-workspace.nix                # composable workspace builder
jigs/
  rust/default.nix              # rust jig (crane + fenix + bacon)
  docs/default.nix              # docs jig (mdbook + mdbook-beans)
lib/
  autowire/                     # nix module/file autowiring helpers
templates/
  beans/                        # beans jig templates
  rust/                         # rust jig templates
  docs/                         # docs jig templates
skills/
  jig.md                        # Claude Code skill definition
```
