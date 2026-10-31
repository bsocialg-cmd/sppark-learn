# Session Log — 2026-10-31 · OpenCode setup & history migration

Not a Spark lesson — this session set up the tooling and moved the course into
this repo so the history travels with it.

## What happened

- Imported the original Spark chat (`ses_e7eceead2ffez5QIaFLDT10r3h`, 154 messages)
  from `spark-learn.json` into the course folder.
- Synced this repo and cloned it to the new PC at the same path the imported
  session points to, so file references in the old chat resolve.
- Added `AGENTS.md` with the rule that every future learning session must commit:
  a dated log in `sessions/`, the chat export in `sessions/exports/`, and any
  notes/exercises/solutions produced along the way.
- Chat export for this session: `sessions/exports/2026-10-31-opencode-setup.json`.

## Commands worth remembering

```bash
opencode session list
opencode session export <session-id> > sessions/exports/YYYY-MM-DD-<slug>.json
opencode session import sessions/exports/<file>.json --directory .
```

## Next step

Resume Lesson 2 in the `spark-learn` session, then add `sessions/2026-11-01.md`
(or the next lesson date) and export the chat as usual.
