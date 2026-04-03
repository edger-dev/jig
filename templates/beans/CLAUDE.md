<!-- jig:beans -->
## Planning

Do NOT write design docs or plans to `docs/plans/`. All planning and design
work should be captured directly in beans (description + body). Beans are the
single source of truth for tracking work.

Do NOT start implementation during the planning stage. The outcome of planning
is beans with clear specs — enough detail for a clean design and implementation
stage later.

## Commit Granularity

Each task should produce 2–3 focused commits:

1. **Tests commit** — the failing tests that define the expected behavior
2. **Implementation commit** — the code that makes them pass, plus any warning fixes
3. **Review fixes commit** (if needed) — issues caught during code review

Each commit should include updated bean files (checked-off todo items, status changes).

## Code Review

After the implementation commit, do a code review before considering the task done.
Prefer spawning a subagent for a fresh perspective — it should review the last 1–2
commits looking for: logic errors, missed edge cases, violations of existing code
patterns, missing test coverage, and clippy-level issues (unnecessary clones, unused
imports, etc.). If a subagent isn't available, self-review by re-reading the full diff.

Fix any real issues found, then commit the fixes separately.

## Acceptance Criteria

Every task must pass before being marked complete:

- All tests pass
- Zero compiler warnings
- Bean todo items all checked off
- Bean marked as `completed` with a `## Summary of Changes` section
- Changes committed with descriptive messages
<!-- /jig:beans -->
