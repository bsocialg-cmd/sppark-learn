#!/usr/bin/env bash
# Spark learning sync.
#
#   1. Export the latest OpenCode session (sanitized) into the PRIVATE repo:
#        ~/.config/opencode/exports/YYYY-MM-DD-<slug>.json
#   2. Commit + push the private repo.
#   3. Commit + push learning files in ~/Desktop/spark-learn (public repo).
#
# Usage:
#   scripts/export-session.sh              # everything
#   scripts/export-session.sh --private-only   # transcript only (used by the 12h timer)
#   scripts/export-session.sh --learning-only  # learning files only
#   scripts/export-session.sh --dry-run
#   scripts/export-session.sh ses_xxxx     # specific session
#
# Scheduled: com.sparklearn.session-export (every 12 hours).

set -uo pipefail

LEARNING_REPO="${LEARNING_REPO:-$HOME/Desktop/spark-learn}"
PRIVATE_REPO="${PRIVATE_REPO:-$HOME/.config/opencode}"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

DRY_RUN=0
DO_PRIVATE=1
DO_LEARNING=1
SES_ID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=1 ;;
    --private-only)   DO_LEARNING=0 ;;
    --learning-only)  DO_PRIVATE=0; DO_EXPORT=0 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) SES_ID="$arg" ;;
  esac
done

log() { printf '%s %s\n' "$LOG_PREFIX" "$*"; }

GIT_ID=()
if [ -z "$(git config --global user.email 2>/dev/null || true)" ]; then
  GIT_ID=(-c user.name=spark-sync -c user.email=spark-sync@localhost)
fi

PATTERNS='gho_[A-Za-z0-9]\{20,\}|github_pat_|ghp_[A-Za-z0-9]\{20,\}|AKIA[0-9A-Z]\{16\}|-----BEGIN [A-Z ]*PRIVATE KEY-----|dapi[0-9a-f]\{32\}|Bearer [A-Za-z0-9_-]\{20,\}|opentunnel\.xyz'

push_with_retry() {
  local dir="$1" label="$2"
  git -C "$dir" pull --rebase --autostash origin main >/dev/null 2>&1 || {
    log "$label: pull failed (conflict?) — leaving commits local"; return 1;
  }
  if git -C "$dir" push origin main >/dev/null 2>&1; then
    log "$label: pushed $(git -C "$dir" log -1 --pretty=%h)"
  else
    log "$label: push failed"; return 1
  fi
}

# ---------------------------------------------------------------- 1. export
if [ "$DO_PRIVATE" = "1" ]; then
  OC="${OC:-/Applications/OpenCode.app/Contents/Resources/opencode-cli}"
  [ -x "$OC" ] || OC="$(command -v opencode || true)"

  if [ -z "$OC" ] || [ ! -x "$OC" ]; then
    log "WARN: opencode CLI not found — skipping export"
  else
    if [ -z "$SES_ID" ]; then
      # `session list` is project-scoped; from outside the project it returns nothing.
      # The HTTP API lists every session, so use it and take the most recently updated.
      read -r SES_ID SES_TITLE < <(
        "$OC" api get /api/session 2>/dev/null | /usr/bin/python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
items = d.get("data") or d.get("sessions") or []
if not items:
    sys.exit(0)
best = max(items, key=lambda s: (s.get("time") or {}).get("updated") or 0)
print(best.get("id", "-"), (best.get("title") or "session").replace("\n", " "))
' 2>/dev/null
      ) || true
      # fallback for older CLIs
      if [ -z "${SES_ID:-}" ]; then
        line="$("$OC" session list --max-count 1 2>/dev/null | head -1 || true)"
        SES_ID="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
        SES_TITLE="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
      fi
    fi
    SES_TITLE="${SES_TITLE:-session}"

    if [ -n "$SES_ID" ]; then
      slug="$(printf '%s' "$SES_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"
      [ -n "$slug" ] || slug="session"
      OUT="$PRIVATE_REPO/transcripts/spark-course-latest.json"
      log "session $SES_ID ($SES_TITLE) -> $OUT"

      if [ "$DRY_RUN" = "1" ]; then
        log "dry run: would export + push to private repo"
      else
        mkdir -p "$PRIVATE_REPO/transcripts"
        if "$OC" session export "$SES_ID" --sanitize > "$OUT" 2>/dev/null; then
          log "exported $(wc -c < "$OUT" | tr -d ' ') bytes"
          if grep -Eq "$PATTERNS" "$OUT"; then
            log "ABORT: possible secret in $OUT — file removed"
            grep -En "$PATTERNS" "$OUT" | head -5 || true
            rm -f "$OUT"
          else
            log "scan: clean"
            git -C "$PRIVATE_REPO" add transcripts >/dev/null
            if git -C "$PRIVATE_REPO" diff --cached --quiet; then
              log "private: no changes"
            else
              git -C "$PRIVATE_REPO" ${GIT_ID[@]+"${GIT_ID[@]}"} commit -q -m "session export: $(basename "$OUT")"
              push_with_retry "$PRIVATE_REPO" "private"
            fi
          fi
        else
          log "export failed"
        fi
      fi
    else
      log "WARN: no session found"
    fi
  fi
fi

# --------------------------------------------------------------- 2. learning
if [ "$DO_LEARNING" = "1" ]; then
  if [ ! -d "$LEARNING_REPO" ]; then
    log "learning: repo not found at $LEARNING_REPO"
  elif ! cd "$LEARNING_REPO" 2>/dev/null; then
    log "learning: cannot access $LEARNING_REPO (macOS TCC?)"
  else
    if [ "$DRY_RUN" = "1" ]; then
      log "dry run: would commit learning files"
    else
      git add -A
      if git diff --cached --quiet; then
        log "learning: nothing to commit"
      else
        SUMMARY="$(git diff --cached --name-only | head -20 | tr '\n' ' ')"
        git ${GIT_ID[@]+"${GIT_ID[@]}"} commit -q -m "chore(sync): $(date '+%Y-%m-%d %H:%M') learning files

$SUMMARY"
        log "learning: committed $(git log -1 --pretty=%h)"
        push_with_retry "$LEARNING_REPO" "learning" || true
      fi
    fi
  fi
fi

log "done"
