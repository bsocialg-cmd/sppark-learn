# sessions/

Chat transcripts, so the **discussion** survives switching PCs — not just the notes.

## Why this folder exists
OpenCode keeps chat history in a local database on each PC. It does **not** sync.
These exported files do (they live in OneDrive).

## Export after a session (on whichever PC you used)

```powershell
opencode session list
opencode session export ses_XXXXXXXX > "spark-course\sessions\YYYY-MM-DD-<topic>.json"
```

Redact secrets before exporting (recommended):
```powershell
opencode session export ses_XXXXXXXX --sanitize > "spark-course\sessions\YYYY-MM-DD-<topic>.json"
```

## Import on the other PC

```powershell
cd "OneDrive - Accionlabs\Documents\Default Project"
opencode session import "spark-course\sessions\YYYY-MM-DD-<topic>.json" --directory .
opencode session list
```

## Live alternative (both PCs on)
```powershell
opencode --server https://<tunnel-host>
```
Requires `opencode pair --remote` on the host PC (links expire in 5 minutes, single use).

## Rules
- **Never commit** a transcript with tokens, connection strings, or personal data.
- Exporting with `--sanitize` redacts transcript text and file contents.
- Prefer one file per session, named `YYYY-MM-DD-<topic>.json`.
- A written digest (`YYYY-MM-DD-<topic>.md`) is usually more useful than the raw JSON —
  keep both if storage allows.

## Naming
```
sessions/
├── 2026-10-28-parallelism.json
├── 2026-10-29-caching-and-plans.json
└── 2026-10-30-architecture-1.json
```
