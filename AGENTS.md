# Project instructions

This repo is the permanent record of the Spark learning course: notes, exercises,
solutions, and the chat transcripts that produced them. The chat is the
classroom; this repo is the archive.

## After every learning session

1. Write or update `sessions/YYYY-MM-DD.md` with:
   - what was covered
   - key definitions (and add new terms to `GLOSSARY.md`)
   - exercises done, mistakes made, open questions
   - the next step for the following lesson
2. Export the full chat transcript to `sessions/exports/YYYY-MM-DD-<slug>.json`:

   ```bash
   opencode session list                         # find the session ID
   opencode session export <session-id> > sessions/exports/YYYY-MM-DD-<slug>.json
   ```

3. Add any new notes, exercises, or solutions in their usual folders.
4. Update `PROGRESS.md` and `LEARNING-PLAN.md` when the plan changes.
5. Commit everything together and push to `origin main`.

## Rules

- Never commit the OpenCode database (`opencode.db*`), credentials, tokens, or `.env` files.
- Session exports contain the full transcript and any file contents read in the chat.
  Check for secrets before exporting into this repo.
- Use `opencode session export --sanitize` when a transcript has to be redacted.
- This repo is public: do not paste Databricks tokens, connection strings, or personal data.
- Notes are Markdown and code is Python; keep the one-lesson-per-file layout.
