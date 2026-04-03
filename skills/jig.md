---
name: jig
description: "Initialize and sync dev environment jigs (beans, rust, python-uv). Use when setting up new projects or updating shared config from the jig repo."
user_invocable: true
---

# jig — Dev Environment Scaffolding & Sync

You are managing project setup using jigs from the `~/edger/jig/` repository.
Each jig is an independent, composable module that provides config files and
CLAUDE.md sections for a specific concern.

## Available Jigs

- **beans** — Issue tracking with beans (`.beans.yml`, hooks, workflow practices)
- **rust** — Rust workspace with bacon diagnostics, nix flake, mise tasks

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

**Options for specific jigs:**

`/jig init rust`:
- Check if beans jig is already present (look for `.beans.yml`). If not, suggest running `/jig init beans` first.
- The nix flake is NOT templated — instead, show the user a sample `flake.nix` that imports `jig.lib.mkRustWorkspace` and let them adapt it. The sample:

```nix
{
  inputs.jig.url = "github:edger-dev/jig";

  outputs = { self, jig }:
    jig.lib.mkRustWorkspace {
      pname = "{{project_name}}";
      src = ./.;
      # buildPackages = [ "my-cli" ];  # omit to build whole workspace
      # wasm = true;                   # include wasm32 target
      # extraDevPackages = pkgs: [ ];  # additional devShell packages
    };
}
```

### `/jig sync [jig-name]`

Update existing jig-managed files from the latest templates. Steps:

1. Detect which jigs are active in the current project:
   - beans: `.beans.yml` exists
   - rust: `bacon.toml` exists
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

### Config files (bacon.toml, .beans.yml, .gitignore, mise tasks)
- On init: create if missing, skip if exists (warn the user)
- On sync: show the diff between current file and template, ask before applying
- For `.gitignore`: append missing entries rather than overwriting

## Important

- Always read template files fresh from `~/edger/jig/templates/` — don't rely on memory
- Ask for placeholder values if they can't be inferred from the project
- The nix flake module is consumed as a flake input, NOT copied — only template config files are copied
- When showing diffs during sync, use a clear format so the user can review changes
