# Rule delivery to the agent

The framework's payoff is a delivery model where the agent's *standing* context
cost trends toward zero even as the rule library grows. Two channels, split by
ladder rung:

**Rung 1+ rules deliver nothing proactively.** They are enforced by the
toolchain, so a violation only ever surfaces *reactively*:
- clippy / dylint / rustc rules → appear in `.bacon-claude-diagnostics` (the
  agent already reads this file; zero extra habit).
- architectural tests → appear as a red `cargo test` in the TDD loop the agent
  already runs.

The agent does **not** need to hold these rules in context. It writes code,
the mechanism catches a violation, the agent reads the diagnostic and fixes it.

**Only rung-0 rules need proactive delivery** — they are the ones no mechanism
yet catches. So the agent-facing hint surface is *exactly the rung-0 set*,
produced from the ledger (a metadata query: rules where `rule::rung=0`).

**The digest shrinks as rules graduate.** Every time a rule moves from rung 0 to
rung 1, one line leaves the hint digest and becomes free, toolchain-enforced
coverage. The registry can grow to hundreds of rules while the hints the agent
must actively remember trend downward. This is the flywheel: mechanization
*subtracts* from context load rather than adding to it.

**Downstream install (built).** jig ships rule *sources*
(`templates/rust/rules/*.md`) plus a `manifest.toml`; a kino is
content-addressed and created by `kinora store`, so jig cannot ship pre-baked
blobs — it materializes them at install time. The installer
`templates/rust/rules/install-rules.sh <project-dir>` does this: it declares the
`rules` root if missing, stores each manifested rule into the project's ledger
(idempotently, skipping ones already present), drift-checks manifest vs sources,
and stages without committing — printing the `kinora commit` (main) + `git`
steps. `/jig init rust` and `/jig sync rust` invoke it when the kinora jig is
active. The enforcement layer (clippy config, arch tests) installs separately and
needs no kinora.

**Rejected:** dumping the full rule catalog into `CLAUDE.md`. That grows the
agent's standing context monotonically — the exact problem the framework exists
to solve.

**Escape hatch:** a project may hand-maintain its rung-0 digest instead of
generating it, until the generator lands.
