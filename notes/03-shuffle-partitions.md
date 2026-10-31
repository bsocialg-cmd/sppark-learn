# Note 03 — `spark.sql.shuffle.partitions` (the "200 default")

## The one-line truth
> It does **not** set how many partitions your data has. It sets how many partitions the
> **result of a shuffle** is split into.

## When it applies
| Operation | Shuffles? |
|---|---|
| `groupBy` | ✅ |
| `join` | ✅ |
| `orderBy` / `sort` | ✅ |
| `distinct` | ✅ |
| `repartition()` | ✅ |
| `select`, `filter`, `withColumn` | ❌ |
| `spark.read...` | ❌ (partitions come from file blocks) |

## Where it lands in a job
```python
df = spark.read.parquet("sales/")          # partitions = file blocks (~128 MB each)
df2 = df.filter(F.col("amount") > 100)     # still file-block partitions
df3 = df2.groupBy("customer").sum("amt")   # ← SHUFFLE
```
```
STAGE 1                       STAGE 2
read → filter                 groupBy result
8 partitions                  200 partitions ← from the config
8 tasks                       200 tasks
        ╲                    ╱
         ╲── shuffle ───────╱
```

## Why 200 is often wrong
It's a **fixed number from ~2015**, tuned for hundreds of GB. It knows nothing about your data.

| Shuffle size | 200 partitions means | Result |
|---|---|---|
| 20 MB | 100 KB each | 200 tasks of pure overhead |
| 20 GB | 100 MB each | fine |
| 2 TB | 10 GB each | spill / OOM / very slow |

## And why it's often harmless now: AQE
Adaptive Query Execution (default since Spark 3.2) watches the shuffle and **merges** tiny
partitions at runtime.

```python
spark.conf.get("spark.sql.adaptive.enabled")                    # "true"
spark.conf.get("spark.sql.adaptive.coalescePartitions.enabled") # "true"
```

## Platform differences
| Environment | Value | Who decides |
|---|---|---|
| OSS Spark | `200` | you |
| Databricks serverless | `auto` | platform, at runtime |
| Databricks classic | usually `200` | you / AQE |

`auto` is a Databricks-only sentinel meaning "I'll size it from the shuffle volume".

## How to see the truth
```python
spark.conf.get("spark.sql.shuffle.partitions")   # intention
df.groupBy("c").count().explain()                # reality: Exchange hashpartitioning(c, 200)
```
> The config states intent; `explain()` shows what actually happened.

## Interview line
> "`spark.sql.shuffle.partitions` is a fixed default of 200 applied to every shuffle result,
> not a data-aware setting. AQE mostly fixes it by coalescing small partitions, but I'd still
> set it explicitly for known-heavy joins."
