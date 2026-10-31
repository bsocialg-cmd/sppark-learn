# Apache Spark — Tutored Course

**Student profile:** Python basic · SQL rusty · Goal: data engineering job · 1–2 hrs/day

## How this works
- One lesson per session. Read, then *type the code yourself* (don't copy-paste).
- **Socratic mode:** after a lesson, I ask **one question at a time** and we discuss your
  answer before moving on. No bulk quizzes.
- Wrong answers are useful — I need to see the reasoning, not just the result.
- I review your code and tell you what a hiring manager would think of it.
- Files here are the permanent record; the chat is the classroom.

## Teaching style (agreed 2026-10-29, reinforced 2026-10-30)
- **Assume zero prior knowledge.** No term is used before it is defined — including "job", "node", "column".
- **Definitions come before code.** Always.
- **Analogy first, jargon second.** Every concept gets a real-world picture.
- **Syntax is taught explicitly.** Every function: what it does, how it's written,
  what each symbol (dot, parentheses, `F.col`) means.
- **Small steps.** One concept or 3–5 functions per turn. Check understanding before moving on.
- **Fundamentals over speed.** Theory is not skipped to "get to the code".
- If I assume knowledge by mistake, say **"noob check"** and I'll back up.
- If an explanation doesn't land, say **"simpler"** and I'll restart it with a new analogy.
- All vocabulary lives in `GLOSSARY.md`.

## Question protocol
- Answer in your own words — one or two sentences is fine.
- Say **"hint"** if stuck, or **"skip"** to move on.
- Say **"why"** any time and I'll go deeper instead of forward.

## Roadmap (≈6 weeks at 1–2 hrs/day)

| Week | Theme | You will be able to... |
|------|-------|------------------------|
| 1 | Mental model + local setup | Explain driver/executors, lazy evaluation, and run your first job |
| 2 | DataFrames & SQL | Clean, join, aggregate real data; read/write Parquet |
| 3 | SQL + windows + UDFs | Rewrite SQL queries in Spark; use window functions correctly |
| 4 | Performance | Read `explain()`, spot shuffles, fix skew, use broadcast joins |
| 5 | Structured Streaming | Build a streaming pipeline with checkpoints |
| 6 | Delta Lake + project | Ship a portfolio ETL/streaming project |

## Repository & sync (agreed 2026-10-31)
- **Remote:** https://github.com/bsocialg-cmd/sppark-learn
- This folder **is** the git repo. Clone it on any other computer:
  `git clone https://github.com/bsocialg-cmd/sppark-learn`
- **After every session** I update `sessions/`, `qa-log.md`, `PROGRESS.md`, and any new
  `notes/`, then commit and push. Nothing lives only in chat.
- The repo is **public** — never commit tokens, passwords, or company data.

## Files
- `LEARNING-PLAN.md` — the full 6-week day-by-day plan
- `PROGRESS.md` — what we've covered, quiz scores, homework
- `qa-log.md` — every question you asked, your answer, the verdict
- `GLOSSARY.md` — every term in plain English + analogy
- `sessions/` — one file per study session
- `notes/` — one note per concept (analogy-first)
- `lesson-01.md` — first lesson
- `setup-databricks.md` — environment setup
- `exercises/` — your code goes here
- `solutions/` — worked answers

## Ground rules
1. No question is too basic — ask.
2. If you're stuck >10 min, ask me instead of grinding.
3. You must be able to *explain* it back in plain English before we move on.
