# Note 01 (from scratch) — Partitions, Tasks, Cores

## First: what is `spark.range(100_000_000)`?

`100_000_000` is just the number **one hundred million**. Python lets you put `_` between digits
for readability — `100_000_000 == 100000000`.

```python
spark.range(100_000_000)
```

means: *"make me a DataFrame with a single column `id`, containing 0, 1, 2, ... 99,999,999."*

It's a **fake dataset generated on the fly** — no file needed. We use it because it's big enough
to see parallelism and costs no download.

```
+---+
| id|
+---+
|  0|
|  1|
|  2|
|...|
+---+
```

---

## The three pieces, one at a time

### 1. Partition = a chunk of the data
Spark never puts all data in one place. It cuts it into chunks.
100,000,000 rows in 8 partitions = 12,500,000 rows each.

### 2. Task = "process one chunk"
Spark creates **one task per partition**. 8 partitions → 8 tasks.
A task carries two things: *the code to run* + *one partition of data*.

### 3. Core = a worker that can do one task at a time
A core cannot multitask. One core = one task at a time.
Cluster total: `executors × cores_per_executor` = total parallel slots.

---

## All together

```
                     DRIVER (the boss with the clipboard)
                     "I need 40 tasks done"
                              |
        +---------------------+---------------------+
        |                                           |
  EXECUTOR 1 (4 cores)                        EXECUTOR 2 (4 cores)
  [c1] [c2] [c3] [c4]                         [c1] [c2] [c3] [c4]
   task  task  task  task                      task  task  task  task
     |     |     |     |                         |     |     |     |
   part1 part2 part3 part4                     part5 part6 part7 part8
```

- 40 partitions → **40 tasks** created
- 8 total cores → **8 tasks run at once**
- 40 ÷ 8 = **5 waves** (5 rounds of "grab a task, finish it, grab the next")

**The limit:** you can never run more tasks at once than you have cores.
And you can never run more tasks at once than you have tasks.

```
concurrent tasks = MIN(tasks, cores) = MIN(partitions, cores)
```

That's the whole rule. "Limit" = whatever is smaller is the bottleneck.

---

## Who decides the partition count? (usually not you)

| Situation | Who partitions it | Default |
|---|---|---|
| Reading Parquet/CSV from storage | The file reader | 1 partition per ~128 MB block |
| `groupBy` / `join` / `orderBy` | The shuffle | `spark.sql.shuffle.partitions` = **200** |
| `repartition(n)` | You | exactly n |
| `coalesce(n)` | You | at most n, no shuffle |
| `spark.range(n, numPartitions=k)` | You | k |

**You almost never assign rows to partitions yourself.** Spark hashes a key (for `groupBy`)
or round-robins rows. You only choose *how many*.

---

## How to choose the number

1. **Aim for 100–200 MB per partition.** Too small → per-task overhead dominates.
   Too big → one task takes forever and can run out of memory.
2. **Or: 2–4 tasks per core.** 8 cores → 16–32 partitions.
3. **Don't hardcode blindly.** Use AQE (Adaptive Query Execution), on by default in modern Spark,
   which merges small shuffle partitions automatically: `spark.sql.adaptive.enabled = true`.

### Two failure modes
- **3 partitions, 8 cores** → 5 cores idle, job takes ~3x longer than needed.
- **10,000 partitions, 8 cores** → 1,250 waves; scheduling overhead > actual work.

---

## One-line summary
> A partition is a chunk of data. A task processes one partition. A core runs one task at a time.
> So parallelism is capped by the smaller of partitions and cores — size partitions to ~128 MB,
> or 2–4 per core.
