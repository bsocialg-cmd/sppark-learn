#!/usr/bin/env bash
# Export the latest OpenCode session + commit all learning files, then push.
#
# Usage:
#   scripts/export-session.sh             # full run (export, scan, commit, push)
#   scripts/export-session.sh --dry-run   # preview only
#   scripts/export-session.sh --no-export # commit/push learning files only
#   scripts/export-session.sh ses_xxxx    # export a specific session
#
# Scheduled by com.sparklearn.session-export (every 12 hours).

set -euo pipefail

REPO="${REPO:-$HOME/Desktop/spark-learn}"
DRY_RUN=0
DO_EXPORT=1
SES_ID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --no-export) DO_EXPORT=0 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) SES_ID="$arg" ;;
  esac
done

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

# --- locate the CLI -------------------------------------------------------
OC="${OC:-/Applications/OpenCode.app/Contents/Resources/opencode-cli}"
if [ ! -x "$OC" ]; then OC="$(command -v opencode || true)"; fi

cd "$REPO"

# --- 1. export the latest session ----------------------------------------
if [ "$DO_EXPORT" = "1" ]; then
  if [ -z "$OC" ] || [ ! -x "$OC" ]; then
    log "WARN: opencode CLI not found — skipping transcript export"
  else
    if [ -z "$SES_ID" ]; then
      line="$("$OC" session list --max-count 1 2>/dev/null | head -1 || true)"
      SES_ID="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
      SES_TITLE="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
    fi
    SES_TITLE="${SES_TITLE:-session}"

    if [ -n "$SES_ID" ]; then
      slug="$(printf '%s' "$SES_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"
      [ -n "$slug" ] || slug="session"
      OUT="sessions/exports/$(date +%Y-%m-%d)-${slug}.json"
      log "session $SES_ID ($SES_TITLE) -> $OUT"

      if [ "$DRY_RUN" = "1" ]; then
        log "dry run: would export, scan, commit and push"
        exit 0
      fi

      mkdir -p sessions/exports
      "$OC" session export "$SES_ID" --sanitize > "$OUT"
      log "exported $(wc -c < "$OUT" | tr -d ' ') bytes"

      # --- secret scan ---------------------------------------------------
      PATTERNS='gho_[A-Za-z0-9]\{20,\}|github_pat_|ghp_[A-Za-z0-9]\{20,\}|AKIA[0-9A-Z]\{16\}|-----BEGIN [A-Z ]*PRIVATE KEY-----|dapi[0-9a-f]\{32\}|Bearer [A-Za-z0-9_-]\{20,\}|opentunnel\.xyz'
      if grep -Eq "$PATTERNS" "$OUT"; then
        log "ABORT: possible secret in $OUT"
        grep -En "$PATTERNS" "$OUT" | head -5 >&2 || true
        rm -f "$OUT"
        exit 3
      fi
      log "scan: clean"
    else
      log "WARN: no session found — skipping export"
    fi
  fi
fi

[ "$DRY_RUN" = "1" ] && { log "dry run: done"; exit 0; }

# --- 2. commit every learning file ---------------------------------------
git add -A

if git diff --cached --quiet; then
  log "nothing to commit"
else
  SUMMARY="$(git diff --cached --name-only | head -20 | tr '\n' ' ')"
  git commit -m "chore(sync): $(date '+%Y-%m-%d %H:%M') learning files + transcript

$SUMMARY" >/dev/null
  log "committed: $(git log -1 --pretty=%h)"
fi

# --- 3. sync with remote and push ----------------------------------------
git pull --rebase --autostash origin main >/dev/null 2>&1 || {
  log "pull failed (conflict?) — leaving local commits in place"; exit 4;
}
git push origin main >/dev/null 2>&1 && log "pushed" || { log "push failed"; exit 5; }
