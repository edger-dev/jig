<!-- jig:rust -->
## Rust Workflow

bacon is running in the background and continuously writes compiler
diagnostics to `.bacon-claude-diagnostics` in the project root.

Before attempting to fix compiler errors, read `.bacon-claude-diagnostics` to see
current errors and warnings with their exact file/line/column locations.
Prefer reading this file over running `cargo check` yourself — it's
already up to date and costs no compile time.

Each line in `.bacon-claude-diagnostics` uses a pipe-delimited format:

```
level|:|file|:|line_start|:|line_end|:|message|:|rendered
```

- `level` — severity: `error`, `warning`, `note`, `help`
- `file` — relative path to the source file
- `line_start` / `line_end` — affected line range
- `message` — short diagnostic message
- `rendered` — full cargo-rendered output including code context and suggestions

After making changes, wait a moment for bacon to recompile, then re-read
`.bacon-claude-diagnostics` to verify the fix.

**All compiler warnings must be fixed before committing.** Zero warnings is the
standard. Check `.bacon-claude-diagnostics` for warnings (not just errors) and
resolve them as part of every change.

If `.bacon-claude-diagnostics` is absent or clearly stale (e.g. the file doesn't
exist after the first save), warn the user that bacon does not appear to
be running and ask them to start it in a Zellij pane with `mise run _bacon-claude-diagnostics`.

## Test-Driven Development

Write tests **before** implementation. The sequence:

1. Write tests that capture the expected behavior from the spec
2. Run `cargo test --workspace` — confirm tests fail for the right reasons (not compilation errors from missing types, but assertion failures or missing functionality)
3. Implement the minimum code to make tests pass
4. Verify all tests pass (not just the new ones)

## Lint Rules

This project encodes coding rules as **lint rules** so the toolchain — not your
memory — enforces them. Each rule is a kino in the `rules` root of the kinora
ledger (`kinora resolve "jig::rust::no-unwrap-in-lib"` prints one). A rule sits
on a **graduation ladder**, and the point of the ladder is that most rules cost
you *zero* context:

- **rung 0 · prose** — a rule no mechanism yet catches. These are the only rules
  you must actively keep in mind. Query them: rules with `rule::rung=0`.
- **rung 1 · warn** — enforced by clippy config or an architectural test. You do
  **not** memorize these. A violation shows up *after* you write it:
  - clippy rules → in `.bacon-claude-diagnostics` (already part of your loop).
  - architectural tests → as a red `cargo test` (e.g. `tests/architecture.rs`).
  Because zero warnings is the commit standard, a rung-1 warning blocks the
  commit just like an error — fix it before committing.
- **rung 2 · deny** — a compile failure; you cannot proceed until it's fixed.
- **rung 3 · structural** — the wrong code doesn't compile at all (types).

So: **write code, let the mechanism catch violations, read the diagnostic, fix
it.** Don't try to hold the whole rulebook in context — that's the failure mode
this design exists to remove.

**When a rule fires,** its message names the rule (e.g. `rule
jig::rust::prefer-file-modules`). Read that rule kino for the rationale and the
escape hatch. Every enforcement point cites its rule: clippy lines carry a
`# rule:` comment in `Cargo.toml`, tests carry `implements: <rule-name>`.

**Escape hatches** are per-rule and local: a justified `#[allow(...)]` on the
line, or a test carve-out. The rule stays in force; the exception is visible.

**Adding or graduating a rule:** author/re-version the rule kino (follow
`jig::meta::rule-schema`), wire its mechanism (a `[workspace.lints]` line or a
test), and cite the rule from that enforcement point. Mechanized rules default
to rung 1 (warn); promote to `deny` deliberately once a rule has proven clean.
<!-- /jig:rust -->
