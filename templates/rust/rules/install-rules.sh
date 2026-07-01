#!/usr/bin/env bash
# install-rules.sh — store the jig rust lint rules into a project's kinora ledger.
#
#   install-rules.sh [--update] <target-project-dir>
#
# Reads the rule sources + manifest.toml beside this script (in the jig repo)
# and stores each rule as a kino in the target project's `rules` root. Run by
# `/jig init rust` / `/jig sync rust` when the kinora jig is active.
#
# Idempotent: rules already present are skipped. With --update, a rule whose
# source body has changed is re-versioned in place (identity preserved, current
# manifest metadata re-applied); unchanged ones are left alone. --update reads
# the *committed* rules root to find each kino's identity + head, so run it after
# committing any pending ledger changes.
#
# Does NOT commit — it stages the store events and prints the `kinora commit` /
# `git` next steps, so the caller decides how to land them (kinora commits roots
# on `main` only).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SRC/manifest.toml"

UPDATE=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    -*) echo "unknown flag: $arg" >&2
        echo "usage: install-rules.sh [--update] <target-project-dir>" >&2; exit 2 ;;
    *)  TARGET="$arg" ;;
  esac
done
if [ -z "$TARGET" ]; then
  echo "usage: install-rules.sh [--update] <target-project-dir>" >&2
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

# ── look up a rule's identity + current head in the committed rules root ─────
# Echoes "<id>\t<head>" for <name>, or nothing if absent/uncommitted. Same
# coupling to kinora's committed root styxl as gen-rung0-digest.sh.
ledger_lookup() {
  local want="$1" ptr hash blob
  ptr="$TARGET/.kinora/roots/rules"
  [ -f "$ptr" ] || return 0
  hash="$(cat "$ptr")"
  blob="$TARGET/.kinora/store/${hash:0:2}/${hash}.styxl"
  [ -f "$blob" ] || return 0
  awk -v want="$want" '
    /^\{kind root/ { next }
    {
      if (!match($0, /metadata \{name [^,}]+/)) next
      nm = substr($0, RSTART + 15, RLENGTH - 15); sub(/[[:space:]]+$/, "", nm)
      if (nm != want) next
      id = ver = ""
      if (match($0, /^\{id [0-9a-f]+/))    id  = substr($0, 5, RLENGTH - 4)
      if (match($0, /version [0-9a-f]+/))  ver = substr($0, RSTART + 8, RLENGTH - 8)
      print id "\t" ver; exit
    }
  ' "$blob"
}

# ── install each rule ────────────────────────────────────────────────────────
installed=0; skipped=0; updated=0; unchanged=0; unresolved=0; deferred=0; orphan=0
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
    if [ "$UPDATE" -ne 1 ]; then
      echo "skip  $name (already in ledger)"
      skipped=$((skipped + 1)); continue
    fi
    # --update: re-version only if the source body actually changed.
    cur="$(kinora -C "$TARGET" resolve "$name" 2>/dev/null || true)"
    if [ "$cur" = "$(cat "$src_md")" ]; then
      echo "ok    $name (up to date)"
      unchanged=$((unchanged + 1)); continue
    fi
    lk="$(ledger_lookup "$name")"; id="${lk%%$'\t'*}"; head="${lk#*$'\t'}"
    if [ -z "$id" ] || [ -z "$head" ]; then
      echo "warn  $name changed but not found in the committed rules root — commit pending ledger changes, then retry --update" >&2
      deferred=$((deferred + 1)); continue
    fi
    # Re-version: NO --root (that would add a duplicate assign → ambiguous
    # commit); identity via --id, current head via --parents. Metadata is
    # per-version, so re-apply the manifest's current values.
    kinora -C "$TARGET" store markdown "$src_md" \
      --provenance jig --name "$name" --id "$id" --parents "$head" \
      -m "rule::ns=$ns" -m "rule::rung=$rung" -m "rule::target-rung=$target" \
      -m "rule::mechanism=$mech" -m "rule::category=$category" \
      -m "status::active=true" >/dev/null
    echo "update $name (re-versioned → rung $rung, $mech, $category)"
    updated=$((updated + 1)); continue
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
echo "rules: installed $installed, updated $updated, unchanged $unchanged, skipped $skipped, deferred $deferred, unresolved $unresolved, orphan $orphan"
if [ "$((installed + updated))" -gt 0 ]; then
  echo "next:"
  echo "  kinora -C \"$TARGET\" commit      # fold roots (run on 'main' only)"
  echo "  git -C \"$TARGET\" add .kinora && git -C \"$TARGET\" commit"
fi
# Fail only when a manifest-declared rule could not be installed.
[ "$unresolved" -eq 0 ]
