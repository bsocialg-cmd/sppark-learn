# Chat exports — moved to the private repo

**Transcripts are not stored in this repository.** This repo is public.

Per `AGENTS.md`, the latest transcript is copied to the private repo
`bsocialg-cmd/opencode-sync-private` as:

```
transcripts/spark-course-latest.json
```

by the scheduled task **`opencode-spark-transcript`**, every 12 hours.

## Manual run

```bash
# on this Mac
./scripts/export-session.sh              # transcript → private repo, then commit learning files
./scripts/export-session.sh --private-only
./scripts/export-session.sh --dry-run

# inspect the scheduled job
launchctl list | grep opencode-spark-transcript
tail -20 ~/Library/Logs/opencode-spark-transcript.log
```

## Restore a session on another machine

```bash
# in a clone of the private repo
opencode session import transcripts/spark-course-latest.json --directory .
```

## Rules

- Transcripts are exported with `--sanitize` and scanned for token-shaped strings
  before commit; the script aborts if it finds any.
- Never commit a transcript to this public repo.
- One rolling file (`spark-course-latest.json`) — the latest session wins.
