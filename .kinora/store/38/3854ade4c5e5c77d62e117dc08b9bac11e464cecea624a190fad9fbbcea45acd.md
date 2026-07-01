# Plan: rung-0 hint digest v3

Generate the agent-facing rung-0 digest — the delivery-spec seam left open by v1
(kino://4df64c1bac779eec6ac0806469abf38d31b92092eb4890319a03e96ac87b86ae).

## Phase 1 — Generator · DONE
`templates/rust/rules/gen-rung0-digest.sh <project-dir> [out]`:
- Reads the committed `rules` root styxl (coupling isolated to one function,
  swappable when kinora ships a list/query command).
- Selects members with `rule::rung 0` AND `status::active true`; excludes rung-1+
  (the `rule::rung 0[,}]` terminator rejects `10`; `target-rung` can't false-match).
- Resolves each and writes name + first-paragraph statement to
  `.kinora/rung0-hints.md`. Empty set → an explicit "None" digest.

## Phase 2 — Wiring · DONE
- rust CLAUDE.md rung-0 bullet now points at `.kinora/rung0-hints.md`.
- `/jig init rust` and `/jig sync rust` regenerate the digest after install/commit.
- jig's own digest generated (surfaces `jig::meta::rule-schema`).

## Phase 3 — Review + validation · DONE
Fresh-eyes subagent review caught two bugs, both fixed and re-tested:
- (high) a failed `kinora resolve` aborted the run under `set -euo pipefail`,
  truncating the digest → `statement_of` now captures with `|| true`.
- (latent) first-match `name` extraction could bind a stray earlier token →
  anchored to `metadata {name …`.
Verified: populated/empty/graduation-flywheel (rung 0→1 drops the line)/jig-ledger
/unresolvable-name cases all correct, exit 0.

## Out of scope (still open)
- Injecting the digest into CLAUDE.md between markers (kept a standalone file).
- Coverage of rules whose rung differs between manifest and a project's local
  re-version is handled (ledger-driven), but a kinora list/query API would let us
  drop the root-blob parsing.
