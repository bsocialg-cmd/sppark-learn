# Chat exports

One JSON file per learning session, named `YYYY-MM-DD-<slug>.json`.

Created from the machine where the session ran:

```bash
opencode session list
opencode session export <session-id> > sessions/exports/YYYY-MM-DD-<slug>.json
```

Restore on another machine:

```bash
opencode session import sessions/exports/<file>.json --directory .
```

Exports contain the full transcript, prompts, and any file contents the agent read.
Keep them private-safe: no tokens or credentials in the chat before exporting.
