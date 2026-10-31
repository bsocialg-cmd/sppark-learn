# Progress Tracker

**Started:** 2026-10-28
**Pace:** 1–2 hrs/day · **Goal:** data engineering job · **Level:** absolute beginner
**Full plan:** `LEARNING-PLAN.md`

## Status
| # | Lesson | Status | Notes |
|---|--------|--------|-------|
| 01 | Mental model + setup | ✅ done (theory) | 7 discussion questions, see `qa-log.md` |
| 01b | Syntax basics (conveyor belt) | 🔄 in progress | `notes/07-functions-primer.md` |
| 02 | DataFrames for real | ⬜ | reading files, schemas, withColumn, nulls |
| 03 | Aggregations & joins | ⬜ | |
| 04 | Spark SQL & windows | ⬜ | |
| 05 | Performance & shuffles | ⬜ | needs local Docker |
| 06 | Structured Streaming | ⬜ | |
| 07 | Delta Lake | ⬜ | |
| 08 | Capstone project | ⬜ | |

## Environment
- **Primary:** Databricks Free Edition (serverless) — workspace live, notebook running
- Community Edition was retired in 2025; Free Edition replaced it
- **Later (Week 4+):** Docker + local PySpark for full control (partitions, RDDs, streaming)
- Java 22 / Python 3.14 are too new for OSS Spark → Docker avoids that problem entirely
- Setup guide: `setup-databricks.md`

## Lesson 1 — what was covered
1. Why Spark exists (data > one machine, in-memory vs MapReduce)
2. Driver / executor / task / core / partition
3. Lazy evaluation: transformations vs actions
4. Partitions & parallelism: `min(partitions, cores)`, waves, failure modes
5. `coalesce` vs `repartition` (merge vs shuffle)
6. Shuffle + partial aggregation (map-side combine)
7. `spark.sql.shuffle.partitions` (200 default vs Databricks `auto`)
8. Reading a physical plan (`explain()`, Photon, stages)
9. `cache()` / `persist()` / eviction / spill
10. Lowest common ancestor rule for caching

## Lesson 1 — questions asked (all logged in `qa-log.md`)
| Q | Topic | Result |
|---|-------|--------|
| pre | 6 cores / 4 partitions | ✅ + refinement |
| 1 | lazy evaluation | ✅ |
| 2 | which calls run a job (a–f) | ✅ |
| 3 | `cache()` and source reads | 📚 taught |
| 3b | cache one node, filter twice | ✅ |
| 4 | cache df vs filtered (LCA) | ✅ main case |
| 4b | 50 GB vs 0.5 GB cache | ❌ corrected |
| 5 | 3 queries, what to cache | 🟡 half right |
| 5b | why oversized cache is worse | ✅ |
| 6 | write the cache code | ❌ corrected |
| 7 | cache in a one-shot job? | 🟡 half right |

## Weak spots to revisit
- **"Bigger cache = better"** — size is a cost, not a benefit. Ask: *how many consumers?*
- **Counting consumers** before caching — repeatedly under-counted (said "once" when it was twice).
- **Assigning transformations** — `filter()` returns a new DataFrame; forgetting to assign.
- **Lazy vs eager** — `cache()` does nothing until an action.
- Reading chained syntax — being addressed with `notes/07-functions-primer.md`.

## Homework (open)
- [ ] Day 5: redo Lesson 1 exercises in `exercises/lesson_01_databricks.py` **without** solutions
- [ ] Time two `count()` calls on a cached DataFrame, send both numbers
- [ ] Answer the 3 "read this line" syntax checks (a/b/c)

## Files
| File | Purpose |
|---|---|
| `LEARNING-PLAN.md` | 6-week day-by-day plan |
| `README.md` | rules, teaching style, roadmap |
| `PROGRESS.md` | this file |
| `qa-log.md` | every question, answer, verdict |
| `notes/01-parallelism.md` | partitions/tasks/cores |
| `notes/02-coalesce-vs-repartition.md` | merge vs shuffle |
| `notes/03-shuffle-partitions.md` | the 200 default |
| `notes/04-reading-plans.md` | reading `explain()` |
| `notes/05-partial-aggregation.md` | `partial_count` |
| `notes/06-cache-and-persist.md` | caching/LCA/eviction |
| `notes/07-functions-primer.md` | beginner syntax + function cheat sheet |
| `lesson-01.md` | full Lesson 1 text |
| `setup-databricks.md` | signup + notebook import |
| `exercises/` | homework notebooks |
| `solutions/` | worked answers |
