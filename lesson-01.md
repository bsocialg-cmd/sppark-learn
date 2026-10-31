# Lesson 1 — Why Spark Exists & How It Thinks

> Goal by the end: you can explain *driver, executor, partition, lazy evaluation* in plain
> English, and you've run your first Spark job.

---

## 1. The problem Spark solves

Imagine a 500 GB CSV of transactions. Your laptop has 16 GB RAM.

Options:
1. **Bigger machine** — expensive, and there's always a bigger dataset.
2. **Split the work across many machines** — this is *distributed computing*.

Hadoop MapReduce did #2 first, but it wrote intermediate results to disk after every step.
Spark keeps intermediate data **in memory** and does the whole computation as one optimized plan.
That's the 10–100x speedup story.

**One-liner:** Spark = a distributed engine for processing data that doesn't fit on one machine.

---

## 2. The cast of characters

| Piece | What it is | Analogy |
|---|---|---|
| **Driver** | Your `main()` program. Builds the plan, schedules tasks, collects results. | Site manager |
| **Executors** | JVMs on worker machines. Hold data in memory, run tasks. | Construction crew |
| **Cluster manager** | YARN / Kubernetes / Standalone. Allocates machines. | HR / staffing agency |
| **Task** | One unit of work on one partition. | One worker's job |
| **Partition** | A chunk of your data. Unit of parallelism. | A pallet of bricks |

**Parallelism rule:** a stage can run at most `min(partitions, cores)` tasks at once.
200 partitions on 8 cores = 25 waves. Too few partitions = idle cores. Too many = overhead.

`local[*]` mode = driver + executor in the same JVM on your laptop. Logically identical to a
cluster, physically one process. That's why you can learn everything locally.

---

## 3. Lazy evaluation — the concept that unlocks Spark

Two kinds of operations:

**Transformations** (lazy — they only *describe* work):
`select`, `filter`, `withColumn`, `join`, `groupBy`, `orderBy`, `distinct`

**Actions** (eager — they *trigger* a job):
`show`, `count`, `collect`, `first`, `take`, `write`, `toPandas`

```python
df2 = df.filter(df.amount > 100)   # instant, nothing ran
df3 = df2.select("customer", "amount")  # instant, still nothing ran
df3.show()                          # <-- NOW Spark runs everything
```

### Why be lazy?
Because Spark sees the **whole chain** before running it, so it can rewrite it:

- **Predicate pushdown** — read only rows matching your filter
- **Column pruning** — read only the 3 columns you selected, not all 80
- **Join reordering** — pick the cheaper join strategy

This is the **Catalyst optimizer**. You write the *what*; Catalyst decides the *how*.

⚠️ Job-interview trap: "Why is my Spark job slow?" — often because they used
`collect()` or a Python loop (`for row in df.collect()`) instead of transformations.

---

## 4. Your first program

```python
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

spark = (
    SparkSession.builder
    .appName("lesson01")
    .master("local[*]")          # use all cores on this laptop
    .getOrCreate()
)

print("Spark version:", spark.version)

data = [
    ("alice", "books",  120.0),
    ("bob",   "books",   45.0),
    ("alice", "games",  300.0),
    ("carol", "games",   75.0),
]

df = spark.createDataFrame(data, "customer string, category string, amount double")

# lazy chain — nothing runs yet
big = df.filter(df.amount > 50).select("customer", "category", "amount")

# action — this is where work happens
big.show()

# see the plan Catalyst produced
big.explain()
```

`explain()` output is your X-ray. We'll read it properly in Week 4.

---

## 5. The SQL you already half-know

DataFrame API and SQL are the *same engine*. Translation table:

| DataFrame | SQL |
|---|---|
| `df.select("a","b")` | `SELECT a, b FROM df` |
| `df.filter(df.a > 10)` | `WHERE a > 10` |
| `df.groupBy("c").agg(F.sum("a"))` | `GROUP BY c` + `SUM(a)` |
| `df.join(other, "id")` | `JOIN other USING (id)` |
| `df.orderBy(F.desc("a"))` | `ORDER BY a DESC` |
| `df.limit(10)` | `LIMIT 10` |
| `df.distinct()` | `SELECT DISTINCT` |
| `df.withColumn("x", F.col("a")*2)` | `SELECT a*2 AS x` |

You can also write literal SQL:
```python
df.createOrReplaceTempView("tx")
spark.sql("SELECT category, SUM(amount) total FROM tx GROUP BY category").show()
```

---

## 6. Python you'll need (since yours is "basic")

```python
# function
def double(x):
    return x * 2

# lambda (tiny inline function)
triple = lambda x: x * 3

# list comprehension
squares = [n * n for n in range(5)]

# dict
row = {"name": "alice", "amount": 120.0}

# tuple unpacking
name, category, amount = ("alice", "books", 120.0)

# f-string
print(f"{name} spent {amount:.2f}")
```

That's ~90% of the Python you need for Spark. The rest you'll pick up.

---

## 7. Exercises — do these now

Create `exercises/lesson_01.py` and work in it.

1. Start a SparkSession named `lesson01`, `local[*]`. Print the version.
2. Build a DataFrame from this list with an **explicit schema string**:
   `[("w1", 5), ("w2", 12), ("w1", 7), ("w3", 20), ("w2", 3)]`
   columns: `week string, units int`
3. Filter to `units > 4` and `show()` it.
4. Group by `week`, sum `units`, order by the sum descending, `show()`.
5. Do #4 again in **SQL** (temp view + `spark.sql`).
6. **Experiments (important):**
   - Remove the `show()` in #3. Does anything run? How do you know?
   - Call `.explain()` on the filtered DataFrame. Paste the output here — we'll read it together.
7. Write 3 sentences in your own words: what is a partition, and why does the number matter?

---

## 8. Checkpoint quiz

Answer without looking back:

1. `df.filter(...)` — does it process any data? Why/why not?
2. Name one thing the optimizer can do *because* evaluation is lazy.
3. Driver vs executor — one sentence each.
4. You have 8 cores and 200 partitions. How many partitions are processed at once? Roughly how many "waves"?
5. Give one transformation and one action from memory.

---

## 9. What "good" looks like (job-market view)

Hiring managers care less about API trivia than:
- Can you make a slow job fast? (Week 4)
- Do you understand shuffles and partitioning? (Week 4)
- Can you build a pipeline end-to-end, not just run a `groupBy`? (Week 5–6)
- Can you explain why you chose Parquet/Delta over CSV? (Week 3)

Answer the exercises + quiz here and I'll grade them.
