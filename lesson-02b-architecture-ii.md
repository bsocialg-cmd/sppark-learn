# Lesson 2b — Architecture II: Jobs, Stages and Tasks

**Level:** beginner · **Time:** 45 min · **Prerequisites:** Lesson 2 (driver, executors, partitions)

## What you will be able to do

1. Explain the difference between a **job**, a **stage** and a **task**
2. Explain what a **shuffle** really does, and why it creates a **barrier**
3. Tell **narrow** from **wide** dependencies by looking at a plan
4. Explain **lineage** and what happens when a worker dies

---

## Part 1 — The three words, one picture

```
JOB        everything triggered by ONE action          (one customer order)
  └─ STAGE a block of work with no shuffle inside       (one cooking phase)
       └─ TASK the work on ONE partition                 (one dish)
```

| Word | Triggered by | How many |
|---|---|---|
| **Job** | one action (`show`, `count`, `write`) | 1 per action |
| **Stage** | a shuffle boundary inside that job | 1 or more per job |
| **Task** | one partition inside a stage | 1 per partition per stage |

**The kitchen:** a customer orders a three-course meal (job). The kitchen works in phases
(stages): starters, then mains, then dessert. In each phase, one dish = one task.

You cannot plate the main course before the starter is cleared: **phase 2 waits for phase 1**.

---

## Part 2 — Why stages exist: the barrier

A **shuffle** is when data must be **redistributed** so that related rows sit together.

Example: you want sales grouped by country.

```
Before:                        After shuffle:
worker1: US, US, IN            worker1: all US
worker2: US, IN, IN            worker2: all IN
worker3: IN, US                worker3: all CA
```

Every worker now needs rows that other workers produced. That can only happen **after** the
previous work is finished and written to disk/network.

So the shuffle is a **barrier**:

```
STAGE 1  ████████████████  (all tasks must finish)
              ║
              ║  shuffle: write to disk, send over network
              ║
STAGE 2  ████████████████  (can only start now)
```

**This is the single most important performance fact in Spark:** shuffles are expensive, and
everything after them waits.

---

## Part 3 — Narrow vs wide dependencies

Every transformation either **does** or **does not** need data from other partitions.

| Type | Meaning | Needs a shuffle? | Example |
|---|---|---|---|
| **Narrow** | each output partition needs **one** input partition | ❌ no | `select`, `filter`, `withColumn`, `map` |
| **Wide** | each output partition needs **many** input partitions | ✅ yes | `groupBy`, `join`, `orderBy`, `distinct`, `repartition` |

**The kitchen version:**

- **Narrow** = "one cook takes one tray and works on it alone." No coordination needed.
- **Wide** = "every cook needs something from every other tray." Everything must be pooled
  on a central table before anyone can continue.

That's why `filter` is cheap (narrow) and `groupBy` is expensive (wide).

> **Interview line:** "Wide dependencies force a shuffle and a stage boundary; narrow
> dependencies let Spark pipeline everything into one stage."

---

## Part 4 — One action, end to end

```python
(spark.read.parquet("sales/")
     .filter(F.col("amount") > 100)     # narrow
     .groupBy("country").sum("amount")  # WIDE → shuffle
     .write.mode("overwrite").parquet("out/")
)
```

```
JOB (triggered by .write)

  STAGE 1 ── read + filter            (narrow only, no barrier)
      │
      ║  SHUFFLE  (hashpartitioning on country)
      │
  STAGE 2 ── group + sum + write      (waits for stage 1)
```

- 1 action → **1 job**
- 1 shuffle → **2 stages**
- each stage has as many **tasks** as it has partitions

---

## Part 5 — Lineage: what happens when a worker dies

Spark does not copy your data three times for safety. Instead it remembers **how the data was
built** — the recipe. That memory is called **lineage**.

If an executor crashes mid-stage:

1. Its partitions are lost
2. Spark reads the lineage (the recipe)
3. It **recomputes** those partitions on another executor
4. The job continues

**Analogy:** a dish is dropped. The chef doesn't panic — the recipe is on the wall, so they
just make it again.

### The cost
Recomputing is fine for a short recipe. It is painful for a long one (10 shuffles deep).

That's why two other tools exist:

| Tool | What it does | Analogy |
|---|---|---|
| **`cache()`** | keeps a result in memory for reuse | photocopy the page |
| **`checkpoint()`** | writes the result to reliable storage and **cuts the lineage** | freeze the dish and label it |

`checkpoint()` is what streaming uses so a restart doesn't replay everything from the beginning.

---

## Part 6 — Reading a job in the Spark UI

When a job runs, the UI shows a DAG (a picture of the stages):

```
Stage 0  ████████████  (12/12 tasks done)
   ║
Stage 1  ████████████  (12/12 tasks done)
```

You can read a lot from that picture:

| What you see | What it means |
|---|---|
| many stages | many shuffles → expensive job |
| one stage much slower | skew, or a bad partition count |
| tasks far more numerous than cores | too many small tasks |
| a stage with 1 task | something collapsed the parallelism |

---

## Exercises

**1. Count them.** A job does: `read → filter → groupBy → orderBy → write`.
How many shuffles? How many stages? *(hint: orderBy also shuffles)*

**2. Narrow or wide?** `select` · `filter` · `join` · `withColumn` · `distinct` · `orderBy`

**3. Spot the barrier.** In this plan, where does stage 1 end?
```
FileScan parquet
+- Filter (amount > 100)
   +- Exchange hashpartitioning(country, 200)
      +- HashAggregate
```
*Read bottom-up.*

**4. Think.** Why does losing an executor not lose the data?

---

## Checkpoint

1. What creates a **job**?
2. What creates a **stage boundary**?
3. What is a **task**?
4. Which is expensive: `filter` or `groupBy`? Why?
5. What is **lineage**, in one sentence?

---

## Summary card

```
1 action        → 1 job
1 shuffle       → +1 stage (a barrier)
1 partition     → 1 task per stage

narrow:  select, filter, withColumn      → no shuffle, cheap
wide:    groupBy, join, orderBy, distinct → shuffle, expensive

lost partition → recomputed from lineage (the recipe)
cache = photocopy · checkpoint = freeze + cut lineage
```

**Next:** back to real code — Lesson 3, DataFrames (reading files, schemas, `withColumn`,
nulls, joins).
