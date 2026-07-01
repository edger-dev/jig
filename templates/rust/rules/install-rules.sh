#!/usr/bin/env bash
# install-rules.sh — store the jig rust lint rules into a project's kinora ledger.
#
#   install-rules.sh <target-project-dir>
#
# Reads the rule sources + manifest.toml beside this script (in the jig repo)
# and stores each rule as a kino in the target project's `rules` root. Run by
# `/jig init rust` / `/jig sync rust` when the kinora jig is active.
#
# Idempotent: rules already present are skipped. Does NOT commit — it stages the
# store events and prints the `kinora commit` / `git` next steps, so the caller
# decides how to land them (kinora commits roots on `main` only).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SRC/manifest.toml"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "usage: install-rules.sh <target-project-dir>" >&2
  exit 2
fi

# ── preconditions ──────────────────────────────────────────────────────────
if ! command -v kinora >/dev/null 2>&1; then
  echo "error: kinora is not on PATH — enable the kinora jig and run 'nix develop'." >&2
  exit 1
fi
if [ ! -d "$TARGET/.kinora" ]; then
  echo "error: no .kinora/ under $TARGET — run '/jig init kinora' first." >&2
  exit 1
fi
if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: $TARGET is not a git repository (kinora tracks the ledger in git)." >&2
  exit 1
fi
if [ -z "$(git -C "$TARGET" config user.name 2>/dev/null || true)" ]; then
  echo "error: git user.name is unset — kinora records it as the kino author." >&2
  exit 1
fi
if [ ! -f "$MANIFEST" ]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 1
fi
CONFIG="$TARGET/.kinora/config.styx"

# ── ensure the `rules` root is declared ──────────────────────────────────────
if ! grep -qE '^[[:space:]]*rules[[:space:]]*\{' "$CONFIG"; then
  awk '
    /^[[:space:]]*roots[[:space:]]*\{/ { inroots = 1 }
    inroots && /^[[:space:]]*\}[[:space:]]*$/ && !added {
      print "  rules { policy \"never\" }"; added = 1; inroots = 0
    }
    { print }
  ' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
  echo "config: declared 'rules' root"
fi

# ── parse manifest.toml into TSV records ─────────────────────────────────────
# Portable (no gawk-only features): split each line on the first '=', strip
# surrounding quotes/space. A '[[rule]]' header flushes the previous record.
parse_manifest() {
  awk -F'=' '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*\[\[rule\]\][[:space:]]*$/ {
      if (name != "") emit(); name=file=ns=rung=target=mech=cat=""; next
    }
    NF >= 2 {
      key = $1; sub(/^[[:space:]]+/, "", key); sub(/[[:space:]]+$/, "", key)
      val = $2; sub(/^[[:space:]]*"?/, "", val); sub(/"?[[:space:]]*$/, "", val)
      if      (key == "name")        name   = val
      else if (key == "file")        file   = val
      else if (key == "ns")          ns     = val
      else if (key == "rung")        rung   = val
      else if (key == "target_rung") target = val
      else if (key == "mechanism")   mech   = val
      else if (key == "category")    cat    = val
    }
    END { if (name != "") emit() }
    function emit() {
      print name "\t" file "\t" ns "\t" rung "\t" target "\t" mech "\t" cat
    }
  ' "$MANIFEST"
}

# ── install each rule ────────────────────────────────────────────────────────
installed=0; skipped=0; unresolved=0; orphan=0
declare -A seen_file
while IFS=$'\t' read -r name file ns rung target mech category; do
  [ -z "$name" ] && continue
  seen_file["$file"]=1
  src_md="$SRC/$file"
  if [ ! -f "$src_md" ]; then
    echo "ERROR $name → manifest lists a source file that is missing: $file" >&2
    unresolved=$((unresolved + 1)); continue
  fi
  if kinora -C "$TARGET" resolve "$name" >/dev/null 2>&1; then
    echo "skip  $name (already in ledger)"
    skipped=$((skipped + 1)); continue
  fi
  kinora -C "$TARGET" store markdown "$src_md" \
    --provenance jig --root rules --name "$name" \
    -m "rule::ns=$ns" -m "rule::rung=$rung" -m "rule::target-rung=$target" \
    -m "rule::mechanism=$mech" -m "rule::category=$category" \
    -m "status::active=true" >/dev/null
  echo "store $name (rung $rung, $mech, $category)"
  installed=$((installed + 1))
done < <(parse_manifest)

# ── drift check: rule sources present but absent from the manifest ───────────
# Soft — an orphan file just isn't installed; it doesn't fail the run.
for md in "$SRC"/*.md; do
  base="$(basename "$md")"
  if [ -z "${seen_file[$base]:-}" ]; then
    echo "warn  $base is present but not listed in manifest.toml (not installed)" >&2
    orphan=$((orphan + 1))
  fi
done

# ── summary + next steps ─────────────────────────────────────────────────────
echo
echo "rules: installed $installed, skipped $skipped, unresolved $unresolved, orphan $orphan"
if [ "$installed" -gt 0 ]; then
  echo "next:"
  echo "  kinora -C \"$TARGET\" commit      # fold roots (run on 'main' only)"
  echo "  git -C \"$TARGET\" add .kinora && git -C \"$TARGET\" commit"
fi
# Fail only when a manifest-declared rule could not be installed.
[ "$unresolved" -eq 0 ]
