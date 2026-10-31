# Spark Course — Q&A Log

Use this to revisit reasoning, not just answers. Newest session at the bottom.

---

## Session 1 — 2026-10-28 (parallelism)

### Q. 6 cores, a file that reads as 4 partitions. Is anything wasted? What would you change?
**Answer:** 2 cores idle. Would create 6 partitions.
**Verdict:** ✅ correct, with a refinement.

**Discussion**
- 4 partitions → 4 tasks → `MIN(4, 6)` = 4 running, 2 cores idle.
- `coalesce(6)` **cannot** increase partitions — it's a silent no-op. You need `repartition(6)`,
  which pays a **full shuffle**.
- 6 is not the ideal target: aim for **2–4 tasks per core** (12–24), so a straggler doesn't stall
  the whole stage.
- On small data (< ~1 GB), the shuffle can cost more than the idle cores. Measure before "fixing".

**Interview takeaway**
> "Partitions cap parallelism at min(partitions, cores). To increase I need repartition, which
> shuffles; coalesce can only merge. I'd target 2–4 tasks per core and only if the data justifies
> the shuffle."

---

## Session 2 — 2026-10-29 (lazy evaluation)

### Q1. `df.filter(...)` then `df.select(...)` — no output, no error, no jobs in the UI. Is something broken?
**Answer:** These are transformations, not actions. Nothing runs until an action is called; Catalyst just builds a plan.
**Verdict:** ✅ Correct.

**Discussion**
- Spark records a **logical plan** ("what to do"). At the action it becomes a **physical plan**
  ("how to do it"), which is when Catalyst's optimizations are applied.
- `filter` + `select` are fused into a single pass — not two separate operations.
- AQE can still revise the physical plan **during** execution.

**Interview takeaway**
> "Transformations are lazy; they extend the logical plan. Actions trigger planning and execution."

---

### Q2. Which of these run a Spark job? (a) count (b) printSchema (c) explain (d) cache (e) show (f) write
**Answer:** a, e, f
**Verdict:** ✅ Correct, including both traps.

| Call | Runs a job? | Why |
|---|---|---|
| `df.count()` | ✅ yes | action |
| `df.printSchema()` | ❌ no | metadata only, no data touched |
| `df.explain()` | ❌ no | prints the plan, doesn't execute it |
| `df.cache()` | ❌ no | only **marks** for caching; materializes on next action |
| `df.show()` | ✅ yes | action |
| `df.write.parquet()` | ✅ yes | action |

**Interview takeaway**
> "`cache()` is lazy — it flags the DataFrame; the first action materializes it. `explain()` and
> `printSchema()` are metadata operations and never trigger a job."

---

### Q3. `df.cache()` → `df.count()` → `df.count()`. How many times is the source read?
**Answer:** _pending_

---

### Q3. `df.cache()` → `df.count()` → `df.count()`. How many times is the source read?
**Answer:** Didn't know `cache` — taught from scratch.
**Verdict:** 📚 learned

**Discussion**
- `cache()` only **marks** the DataFrame; data is stored during the **first action**.
- With cache: source read **1×**, second count served from memory.
- Without cache: **every action re-reads** the source (2 reads).
- `cache()` = `persist(MEMORY_AND_DISK)` for DataFrames.
- `unpersist()` frees it.

**Interview takeaway**
> "`cache()` materializes lazily on first use and is reused by later actions. Without it, each action re-executes the full plan from the source."

---

### Q3b. `df.cache()` then `df.filter(...).count()` twice — is the source read twice? Is the filter computed twice?
**Answer:** Source read once (from cache); filter computed twice.
**Verdict:** ✅ Correct.

**Discussion**
- A cache covers **one node**, not the whole query.
- Downstream operations (the filter) still re-run on every action.
- Fix: cache the *filtered* DataFrame if that's what you reuse.

**Interview takeaway**
> "`cache()` materializes a single logical node — everything downstream still re-executes."

---

### Q4. 5 reports on a 50 GB file, all filtered `amount > 100`. Cache `df` or the filtered 1 GB?
**Answer:** The filtered DataFrame.
**Verdict:** ✅ Correct (main case). The exception needed teaching.

**Discussion — "lowest common ancestor" (LCA)**
- Draw the query tree. Cache the **last node every consumer passes through**.
- All 5 share the filter → cache the 1 GB.
- If the 5 used *different* filters, there's no shared small node → the source is the LCA → cache `df`.
- Rule: maximise **hit rate**, then minimise size.

**Dam analogy 🌊**
> A river splits into branches. Build the dam **just before the split** — every branch downstream is served, while holding the least water. A dam on one branch serves only that branch; a dam at the source serves all but holds everything.

**Interview takeaway**
> "I cache at the lowest common ancestor of all consumers — the shared node closest to the outputs."

---

### Q4b. Cache 50 GB used 5× vs cache 0.5 GB used 5× — which wins?
**Answer (first attempt):** The 50 GB one, "because it caches bigger memory."
**Verdict:** ❌ — corrected.

**Discussion**
- Size is **not** a benefit; it's a **cost**.
- If the same 5 queries only read the 0.5 GB slice, both caches give identical speedup.
  The 50 GB holds 49.5 GB that **nobody reads**.
- Value ≈ (work saved per hit × hits) − (memory spent). Size only appears on the cost side.
- **Photocopy analogy:** 5 people need page 10 of a 1,000-page manual. Photocopying the whole
  manual helps them exactly as much as copying page 10 — for 1,000× the paper.

**Interview takeaway**
> "Cache the rows that will be read again. Rows nobody reads are expensive furniture."

---

### Q5. Three queries: (a) all years, (b) year=2024, (c) year=2024. What do you cache?
**Answer (first attempt):** Nothing — "hits are almost once, filter does the job better."
**Verdict:** 🟡 Half right.

**Discussion**
- `filter(year=2024)` has **2 consumers** (b and c), not one. Not "once".
- Caching it = ~5 GB for 2 hits. Query (a) is the outlier and stays cold.
- "Nothing" is only right if each query runs **once, ever**.
- Predicate pushdown does make the filter cheap — so the benefit is smaller than it looks,
  but 2 hits on 5 GB is still a reasonable cache.

**Interview takeaway**
> "Count the consumers of each node. A 1-consumer cache is waste; 2+ consumers only has to beat re-reading that subset."

---

### Q5b. Why is an oversized cache worse than no cache?
**Answer:** Spark recomputes the evicted piece. ✅

**Discussion**
- **Spill** = move data to disk (extra write + read).
- **Evict** = drop from memory; it must be **recomputed from lineage** (re-read source + redo transforms).
- Desk analogy: a desk holding 16 folders; asked to keep 50. The overflow goes back to the cabinet,
  and to make room Spark keeps throwing folders off the desk — sometimes the one you need next.
- Recompute also depends on determinism: a random/timestamp UDF can return a **different** value.
  (This is why `cache()` is not a checkpoint.)

**Interview takeaway**
> "A cache larger than memory spills and evicts, so you pay for RAM and still recompute. The best cache is one that fits."

---

### Q6. Write code: read `sales/`, keep year=2024, cache it, materialise it.
**First attempt:**
```python
df = spark.read.parquet("sales/")
df.cache()
df.filter("year == 2024")
```
**Verdict:** ❌ three bugs.
1. `filter()` returns a **new** DataFrame — the result was never assigned (immutability).
2. Cached `df` (all 50 GB) instead of the filtered result — the Q3b mistake repeated.
3. No action → nothing materialised.

**Corrected:**
```python
filtered = df.filter(F.col("year") == 2024)
filtered.cache()
filtered.count()
```

**Follow-up: why is `count()` needed?** — answered: "action is required" ✅
- `cache()` is lazy; the first **action** computes the data and fills the cache.
- Any action works; `count()` is the cheapest.

**Interview takeaway**
> "Assign every transformation to a variable, cache the node you'll reuse, and force it with an action."

---

### Q7. 100 GB job: read → filter → aggregate → write. Runs **once**. Cache anything?
**Answer:** "Cache the filter results so the aggregation runs on the small cached set, if the filter shrinks the data a lot."
**Verdict:** 🟡 half right — missed the point that the job runs once.

**Discussion**
- Within a single action the stages **chain**; the aggregation reads the filter's output,
  never the raw source. The 100 GB is read **once already**.
- Caching inserts a copy step (write to RAM → read back) and acts as a **barrier** that
  stops pipelining. Pure overhead in a one-shot linear job.
- **Exception:** if the same filtered DataFrame is used **more than once in the same plan**
  (e.g. `filtered.join(filtered, ...)`), Spark computes it twice → caching helps.

**Interview takeaway**
> "Caching saves recomputation. In a one-pass linear job there is no recomputation, so caching only adds overhead."

---

## Doubts & clarifications asked during Session 2

| Doubt | Short answer |
|---|---|
| What is `spark.range(100_000_000)`? | `100_000_000` is just 100 million (`_` is a readability separator). `range(n)` builds a fake table with one column `id` = 0…n-1. |
| "200 partitions by default" — what does that mean? | `spark.sql.shuffle.partitions = 200` only sets the partition count of a **shuffle result** (after `groupBy`/`join`/`orderBy`), not of data you read. Databricks serverless sets it to `auto`. |
| What is `partial_count`? | Map-side pre-aggregation: each partition counts its own rows **before** the shuffle, so only `(key, count)` crosses the network, not raw rows. |
| `NameError: F is not defined` | Missing `from pyspark.sql import functions as F`. `F` is an alias you create; Spark doesn't define it. |
| "Why is caching bigger memory better?" | It isn't. Size is a **cost**, not a benefit. Value = work saved per hit × hits − memory spent. |
| "Explain eviction/spill simply" | Desk holding 16 folders; asked to keep 50. Overflow goes back to the cabinet (spill); to make room, folders get thrown off the desk (evict) and must be rebuilt (recompute). |
| "If caching df is fine, why is it bad here?" | "Not wrong" meant *won't break*, not *efficient*. With a 1% selective filter, you spend 50 GB of RAM to save a read that predicate pushdown already made cheap. |
| "I don't understand ancestor/LCA" | River with branches: build the dam **just before the split**, so every branch downstream is served while holding the least water. |

---

## Syntax gaps identified (2026-10-29)
- Didn't know how to read a chained line (`df.filter(...).select(...)`).
- Unclear what `F` and `F.col()` are.
- Didn't know a transformation must be **assigned** to a variable.
- Unclear that `cache()` needs an action to take effect.
→ Addressed with `notes/07-functions-primer.md` and the "conveyor belt" syntax lesson.

---

## Syntax checks (conveyor-belt lesson)

**Check a) `df.select("customer")`**
Answer: "column to display" → 🟡 half right.
- `select` returns a **new DataFrame** with fewer columns. It does not display anything.
- **Databricks caveat:** the last expression in a cell is auto-displayed by the notebook —
  that's the notebook, not `select`.

**Check b) `df.filter(F.col("amount") > 500).count()`** → ✅ correct.
- Filters rows, then `count()` (an action) returns a number.
- Wording fix: counts **rows**, not customers (a customer with 3 orders = 3 rows).

**Check c) `withColumn` + `select`, no action** → ✅ correct, including "nothing runs without an action".
- Applied lazy evaluation unprompted. Good sign.

---

## Patterns to watch (from mistakes so far)
- `F` must be imported: `from pyspark.sql import functions as F`
- `.alias()` is required after aggregations, or columns get names like `sum(units)`
- `coalesce` cannot increase partitions
