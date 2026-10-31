# Apache Spark — Full Learning Plan

**Student:** Python basic · SQL rusty · target: data engineering job
**Pace:** 1–2 hrs/day, 5 days/week (~10 hrs/week) · **Duration:** 6 weeks (~60 hrs)
**Environment:** Databricks Free Edition (Weeks 1–3), Docker + local PySpark (Weeks 4–6)

**Calendar:** W1 Oct 28–Nov 3 · W2 Nov 4–10 · W3 Nov 11–17 · W4 Nov 18–24 · W5 Nov 25–Dec 1 · W6 Dec 2–8

---

## The rules of the plan

1. **80% typing, 20% reading.** Watching/reading without coding doesn't stick.
2. **Every day ends with a runnable artifact.** A notebook cell that works.
3. **One question at a time** in chat — we discuss before moving on.
4. **Notes go in `qa-log.md`** — your revision material.
5. **Stuck >15 min? Ask.** Grinding on syntax is not learning.
6. **You can explain it in plain English** before the topic counts as done.

### Daily rhythm (90 min)
| Minutes | Activity |
|---|---|
| 15 | Read the concept / lesson file |
| 50 | Type code, break it, fix it |
| 15 | Do the day's exercise unaided |
| 10 | Write 3 lines in your own words in `qa-log.md` |

---

## Week 1 — Mental model ✅ (in progress)

**Outcome:** you can explain how Spark executes a job and read a physical plan.

| Day | Topic | Lab |
|---|---|---|
| 1 ✅ | Why Spark; driver/executor; lazy evaluation | First DataFrame, `explain()` |
| 2 ✅ | Partitions, tasks, cores; coalesce vs repartition | Partition experiments |
| 3 ✅ | Shuffles, partial aggregation, reading plans | Interpret your own plan |
| 4 ✅ | Caching, LCA rule, eviction/spill | Cache & time two `count()`s |
| 5 | **Architecture I:** driver, executors, cluster manager, deployment modes | Draw the cluster yourself |
| 6 | **Architecture II:** job → stage → task, narrow vs wide deps, lineage & fault tolerance | Trace one query through all layers |
| 7 | Consolidation | Redo Lesson 1 exercises without solutions |

**Checkpoint:** explain out loud — *why is my job slow when it has 3 partitions on 8 cores?*

---

## Week 2 — DataFrames for real

**Outcome:** clean and reshape a messy real dataset without help.

| Day | Topic | Lab |
|---|---|---|
| 6 | Reading CSV/Parquet/JSON; explicit schemas; `inferSchema` traps | Load a CSV 3 ways, compare types |
| 7 | `select`, `filter`, `withColumn`, `cast`, `drop`, rename | Build derived columns |
| 8 | `when`/`otherwise`, nulls (`na.drop`, `na.fill`, `isNull`) | Clean a dirty file |
| 9 | Dedupe (`dropDuplicates`), sorting, `limit`, sampling | Dedupe on a business key |
| 10 | Writing: modes, `partitionBy`, file sizing, small-files problem | Write Parquet, check file count |
| 11–12 | **Mini-project:** raw CSV → clean Parquet, documented | `projects/02-clean-data/` |

**Checkpoint:** a clean Parquet table + a notebook a colleague could rerun.

**Dataset:** Online Retail II (UCI) or a Databricks sample table.

---

## Week 3 — Aggregations, joins, SQL

**Outcome:** answer business questions with both the DataFrame API and SQL.

| Day | Topic | Lab |
|---|---|---|
| 13 | `groupBy` + `agg` (multiple metrics), `pivot` | Revenue per country/quarter |
| 14 | Joins: inner/left/anti/semi; join keys; **row explosion** | Deliberately create a duplicate-key join, then fix it |
| 15 | Spark SQL: temp views, CTEs, `EXPLAIN` | Rewrite Day 13 in SQL |
| 16 | Window functions: `row_number`, `rank`, `lag/lead`, running totals | Top-N per group |
| 17 | UDFs: why to avoid, `pandas_udf` / `mapInPandas` | Replace a UDF with built-ins |
| 18–19 | **Mini-project:** 3 business questions → one report table | `projects/03-analytics/` |

**Checkpoint:** you can convert any SQL query you write into DataFrame code and back.

---

## Week 4 — Performance (the interview differentiator)

**Outcome:** take a slow job and make it measurably faster, with evidence.

> Switch to local Docker PySpark here — full control of partitions, `spark-submit`, Spark UI.

| Day | Topic | Lab |
|---|---|---|
| 20 | Catalyst, physical plans, predicate pushdown, column pruning | Read 3 plans, spot the optimizations |
| 21 | Shuffle mechanics, partitioning, `repartition` vs `coalesce` vs `partitionBy` | Measure shuffle bytes in the UI |
| 22 | Join strategies: broadcast vs sort-merge; `broadcast()` hint | Force both, compare timings |
| 23 | **Skew**: detection, salting, AQE skew handling | Fix a deliberately skewed join |
| 24 | AQE settings, file formats (Parquet vs Delta), compaction, Z-order | Compact 1,000 small files |
| 25–26 | **Lab:** optimize a slow NYC taxi job; before/after table | `projects/04-performance/` |

**Checkpoint:** a before/after timing table you can put in a portfolio README.

---

## Week 5 — Structured Streaming

**Outcome:** build a streaming pipeline that survives restarts.

| Day | Topic | Lab |
|---|---|---|
| 27 | Streaming model, micro-batches, `readStream` | File source → console sink |
| 28 | Output modes, triggers, `foreachBatch` | Append vs update vs complete |
| 29 | Windows + watermarks (late data) | 10-minute tumbling windows |
| 30 | Checkpointing, exactly-once, failure recovery | Kill and restart mid-stream |
| 31 | Kafka concepts + Delta sink | Simulated event stream → Delta |
| 32–33 | **Mini-project:** streaming ingest → aggregation → Delta | `projects/05-streaming/` |

**Checkpoint:** explain what a watermark does and why checkpoints are mandatory.

---

## Week 6 — Delta Lake + capstone

**Outcome:** a portfolio project that looks like real work.

| Day | Topic | Lab |
|---|---|---|
| 34 | Delta: ACID, time travel, schema evolution | `DESCRIBE HISTORY`, restore a version |
| 35 | `MERGE` (upserts), `OPTIMIZE`, `VACUUM` | Upsert an incremental batch |
| 36 | Medallion architecture (bronze/silver/gold) | Design your layers |
| 37 | Orchestration concepts (Airflow / Databricks Jobs), testing | Wrap pipeline in tasks |
| 38–40 | **Capstone:** end-to-end pipeline | `projects/06-capstone/` |
| 41 | README, diagrams, timings, GitHub polish | Publish it |
| 42 | Interview prep | 30 questions + STAR stories |

**Capstone shape:** ingest raw → bronze → clean/dedupe → silver → aggregate → gold → dashboard/export, with tests, a README explaining trade-offs, and a "what I'd improve at 10x scale" section.

---

## Weekly checkpoints (self-assessment)

| Week | You pass if you can... |
|---|---|
| 1 | Explain partitions/tasks/cores, lazy eval, and read a plan |
| 2 | Load, clean, and write a dataset without googling syntax |
| 3 | Write joins and window functions in both API and SQL |
| 4 | Diagnose a slow job and prove the fix with timings |
| 5 | Build a checkpointed streaming pipeline |
| 6 | Show a repo a hiring manager would read |

---

## Job-readiness toolkit

**Must-know interview topics**
- Lazy evaluation / DAG / stages
- Shuffle — why it's expensive, how to reduce it
- Partition sizing, small files
- Broadcast vs sort-merge join, skew
- `cache` vs `persist` vs `checkpoint`
- Delta vs Parquet, ACID, time travel, MERGE
- Streaming: watermark, checkpoint, exactly-once
- AQE

**Portfolio (3 items)**
1. Batch ETL with tests and a clean README (Week 3 project, upgraded)
2. Performance case study with before/after numbers (Week 4)
3. Streaming + Delta pipeline (Weeks 5–6)

**Optional credibility boost:** Databricks Certified Data Engineer Associate — the Week 1–6 material covers most of the syllabus.

---

## If you fall behind
- **1 day:** skip the lab, do the checkpoint question.
- **3+ days:** drop Week 5's Kafka day and Week 6's orchestration day. Never skip Week 4.
- **Lost motivation:** build something you'd actually use (your own expense data, a hobby dataset). Spark on real data you care about beats another tutorial.

## Resources (only these — avoid tutorial-hopping)
- **Docs:** spark.apache.org/docs/latest (API reference, not tutorials)
- **Book:** *Spark: The Definitive Guide* (chapters 1–4, 8, 15–18, 22)
- **Databricks:** docs + Free Edition sample tables (`samples.nyctaxi.trips`, `samples.bakehouse`)
- **Practice:** LeetCode SQL → rewrite in PySpark
- **Don't** collect 10 Udemy courses. One plan, executed, wins.
