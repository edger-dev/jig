---
name: jig
description: "Initialize and sync dev environment jigs (beans, rust, docs). Use when setting up new projects or updating shared config from the jig repo."
user_invocable: true
---

# jig — Dev Environment Scaffolding & Sync

You are managing project setup using jigs from the `~/edger/jig/` repository.
Each jig is an independent, composable module that provides config files and
CLAUDE.md sections for a specific concern.

## Available Jigs

- **beans** — Issue tracking with beans (`.beans.yml`, hooks, workflow practices)
- **rust** — Rust workspace with bacon diagnostics, mise tasks, TDD workflow
- **docs** — Documentation with mdbook, optional mdbook-beans integration

## Commands

### `/jig init <jig-name> [options]`

Scaffold a jig into the current project. Steps:

1. Read the jig's templates from `~/edger/jig/templates/<jig-name>/`
2. For each template file:
   - If the target file doesn't exist: create it, replacing `{{placeholders}}` with project values
   - If the target file exists: merge intelligently (see Merging Rules below)
3. Report what was created/updated

**Placeholders** (ask the user if not obvious from context):
- `{{project_name}}` — human-readable project name
- `{{project_prefix}}` — short prefix for bean IDs (usually lowercase project name)
- `{{project_description}}` — one-line project description

**Options for specific jigs:**

`/jig init beans`:
- Creates `.beans.yml`, `.beans/.gitignore`, merges hooks into `.claude/settings.json`
- Appends beans CLAUDE.md section (planning, commits, review, acceptance criteria)

`/jig init rust`:
- Check if beans jig is already present (look for `.beans.yml`). If not, suggest running `/jig init beans` first.
- Creates `bacon.toml`, `.gitignore`, merges mise tasks
- Appends rust CLAUDE.md section (bacon workflow, TDD)
- The nix flake is NOT templated — instead, show the user a sample `flake.nix` using the new `mkWorkspace` API:

```nix
{
  inputs.jig.url = "github:edger-dev/jig";

  outputs = { self, jig }:
    jig.lib.mkWorkspace
      {
        pname = "{{project_name}}";
        src = ./.;
        # extraDevPackages = pkgs: [ ];
      }
      {
        rust = {
          # buildPackages = [ "my-cli" ];  # omit to build whole workspace
          # wasm = true;                   # include wasm32 target
        };
      };
}
```

`/jig init docs`:
- Creates `docs/` directory with `book.toml`, `src/SUMMARY.md`, `src/introduction.md`
- Merges docs mise tasks (`_docs-serve`, `docs-build`)
- Appends docs CLAUDE.md section
- **Beans integration**: If beans jig is active (`.beans.yml` exists), ask whether to enable beans in docs:
  - If yes: append `book.beans.toml` contents to `book.toml`, copy `src/beans-sidebar.css` into `docs/src/`
  - If no: use base `book.toml` only, skip `beans-sidebar.css`
  - Remind the user to set `docs = { beans = true; }` in their flake's jigs when beans is enabled

### `/jig sync [jig-name]`

Update existing jig-managed files from the latest templates. Steps:

1. Detect which jigs are active in the current project:
   - beans: `.beans.yml` exists
   - rust: `bacon.toml` exists
   - docs: `docs/book.toml` exists
2. For each active jig (or just the specified one):
   - Read the current project files and the jig templates
   - Compare CLAUDE.md sections (between `<!-- jig:name -->` markers) — update if template is newer
   - Compare config files — show diff and ask before applying changes
   - Merge `.claude/settings.json` hooks (add missing, don't remove existing)
3. Report what was updated

### `/jig list`

Show which jigs are active in the current project and their status.

## Merging Rules

### CLAUDE.md
- Each jig owns the content between its markers: `<!-- jig:<name> -->` ... `<!-- /jig:<name> -->`
- On init: append the jig's section to the existing CLAUDE.md (after the project header)
- On sync: replace the content between markers with the latest template
- Never touch content outside jig markers — that's project-specific

### .claude/settings.json
- Read `claude-settings-hooks.json` from the jig template
- Merge hooks into the existing settings.json:
  - For each hook event (SessionStart, PreCompact, etc.): add entries that don't already exist
  - Never remove existing hooks — other jigs or the user may have added them
- Preserve all other settings.json keys (permissions, enabledPlugins, etc.)

### Config files (bacon.toml, .beans.yml, book.toml, .gitignore, mise tasks)
- On init: create if missing, skip if exists (warn the user)
- On sync: show the diff between current file and template, ask before applying
- For `.gitignore`: append missing entries rather than overwriting
- For `book.toml`: base template is `book.toml`; if beans is active, also concatenate `book.beans.toml` and ensure `src/beans-sidebar.css` exists

## Nix Flake Guidance

When the user has multiple jigs, show the combined `mkWorkspace` form:

```nix
{
  inputs.jig.url = "github:edger-dev/jig";

  outputs = { self, jig }:
    jig.lib.mkWorkspace
      {
        pname = "my-project";
        src = ./.;
      }
      {
        rust = { buildPackages = [ "my-cli" ]; wasm = true; };
        docs = { beans = true; };
      };
}
```

The nix jigs (`rust`, `docs`) compose automatically — `mkWorkspace` merges
packages, checks, and devShell from all active jigs.

## Important

- Always read template files fresh from `~/edger/jig/templates/` — don't rely on memory
- Ask for placeholder values if they can't be inferred from the project
- The nix flake module is consumed as a flake input, NOT copied — only template config files are copied
- When showing diffs during sync, use a clear format so the user can review changes
