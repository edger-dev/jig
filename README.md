# jig

Nix flake modules and Claude Code skills for consistent dev environments across projects.

## Jigs

Each jig is an independent, composable module:

| Jig | What it provides |
|-----|-----------------|
| **beans** | Issue tracking config, Claude Code hooks, workflow practices (planning, commits, code review) |
| **rust** | Nix flake module (`mkRustWorkspace`), bacon diagnostics, mise tasks, TDD workflow |

## Usage

### Nix Flake (Rust)

```nix
{
  inputs.jig.url = "github:edger-dev/jig";

  outputs = { self, jig }:
    jig.lib.mkRustWorkspace {
      pname = "my-project";
      src = ./.;
      # buildPackages = [ "my-cli" ];
      # wasm = true;
      # extraDevPackages = pkgs: [ pkgs.dioxus-cli ];
    };
}
```

Update toolchain/packages: `nix flake update jig`

### Claude Code Skill

Copy `skills/jig.md` into your project's `.claude/skills/` (or your global `~/.claude/skills/`), then:

```
/jig init beans       # scaffold beans issue tracking
/jig init rust        # scaffold rust workspace config
/jig sync             # update jig-managed files from latest templates
/jig list             # show active jigs
```

## Structure

```
flake.nix                       # exports lib.mkRustWorkspace
rust/mk-workspace.nix           # rust dev environment builder
templates/
  beans/                        # beans jig templates
    .beans.yml
    .beans/.gitignore
    CLAUDE.md                   # planning + workflow sections
    claude-settings-hooks.json  # hooks to merge into .claude/settings.json
  rust/                         # rust jig templates
    bacon.toml
    CLAUDE.md                   # rust workflow + TDD sections
    .gitignore
    mise-tasks.toml
skills/
  jig.md                        # Claude Code skill definition
```
