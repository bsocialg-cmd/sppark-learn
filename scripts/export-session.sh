#!/usr/bin/env bash
# Export the latest OpenCode session to the repo, scan it for secrets, commit and push.
#
# Usage:
#   scripts/export-session.sh            # export latest session, commit, push
#   scripts/export-session.sh <ses_id>   # export a specific session
#   scripts/export-session.sh --dry-run  # show what would happen, change nothing
#
# Runs on macOS (uses the CLI bundled inside OpenCode.app).
# On Windows, use the equivalent opencode-cli.exe path.

set -euo pipefail

REPO="${REPO:-$HOME/Desktop/spark-learn}"
DRY_RUN=0
SES_ID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) SES_ID="$arg" ;;
  esac
done

# --- locate the CLI -------------------------------------------------------
OC="${OC:-/Applications/OpenCode.app/Contents/Resources/opencode-cli}"
if [ ! -x "$OC" ]; then
  OC="$(command -v opencode || true)"
fi
if [ -z "$OC" ] || [ ! -x "$OC" ]; then
  echo "error: opencode CLI not found. Set OC=/path/to/opencode-cli" >&2
  exit 1
fi

cd "$REPO"

# --- pick the session -----------------------------------------------------
if [ -z "$SES_ID" ]; then
  line="$("$OC" session list --max-count 1 2>/dev/null | head -1)"
  SES_ID="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
  SES_TITLE="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
fi
[ -n "$SES_ID" ] || { echo "error: could not determine a session id" >&2; exit 1; }
SES_TITLE="${SES_TITLE:-session}"

slug="$(printf '%s' "$SES_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"
[ -n "$slug" ] || slug="session"
OUT="sessions/exports/$(date +%Y-%m-%d)-${slug}.json"

echo "session : $SES_ID  ($SES_TITLE)"
echo "output  : $OUT"

if [ "$DRY_RUN" = "1" ]; then
  echo "dry run : would export, scan, commit and push"
  exit 0
fi

# --- export (sanitized) ---------------------------------------------------
mkdir -p sessions/exports
"$OC" session export "$SES_ID" --sanitize > "$OUT"
echo "exported: $(wc -c < "$OUT" | tr -d ' ') bytes"

# --- secret scan ----------------------------------------------------------
# Anything matching here aborts the commit. Add patterns as you discover them.
PATTERNS='gho_[A-Za-z0-9]\{20,\}|github_pat_|ghp_[A-Za-z0-9]\{20,\}|AKIA[0-9A-Z]\{16\}|-----BEGIN [A-Z ]*PRIVATE KEY-----|dapi[0-9a-f]\{32\}|Bearer [A-Za-z0-9_-]\{20,\}'
if grep -Eq "$PATTERNS" "$OUT"; then
  echo "ABORT: possible secret found in $OUT" >&2
  grep -En "$PATTERNS" "$OUT" | head -5 >&2
  exit 3
fi
echo "scan    : clean"

# --- commit and push ------------------------------------------------------
git add "$OUT"
if git diff --cached --quiet; then
  echo "nothing to commit (export unchanged)"
  exit 0
fi
git commit -m "docs(sessions): export $(basename "$OUT" .json) transcript (sanitized)"
git pull --rebase --autostash origin main
git push origin main
echo "done    : pushed"
