# Note 06 — Cache, persist, eviction, and the LCA rule

## Why caching exists
Every **action** re-runs the whole plan from the source:

```python
df = spark.read.parquet("sales/")   # 50 GB
df.count()          # reads 50 GB
df.avg("amount")    # reads 50 GB again
df.groupBy("x")...  # reads 50 GB again
```

`cache()` = *"after computing me once, keep me and reuse me."*

**Analogy:** instead of walking to the filing cabinet three times, photocopy the document
once and keep it on your desk.

## It is lazy
```python
df.cache()      # 1. marks the DataFrame — instant, no data touched
df.count()      # 2. computes AND stores in memory ← caching happens HERE
df.avg("amt")   # 3. reads memory, not disk
```

`cache()` = `persist(MEMORY_AND_DISK)` for DataFrames.
`unpersist()` releases it.

## It covers ONE node, not the query
```python
df.cache()
df.filter(...).count()   # filter still runs — every time
df.filter(...).count()   # filter runs AGAIN
```
The cache saves the **source read**, not downstream work. Cache the node you actually reuse.

## The LCA (lowest common ancestor) rule
Draw the query tree; cache the **last node every consumer passes through**.

```
              read df (50 GB)
        ┌──────────┼──────────┐
        │          │          │
      (a)   filter(year=2024)
     all years        │
                 ┌────┴────┐
                (b)       (c)
```
- `filter(year=2024)` is shared by b and c → cache **it** (~5 GB, 2 hits).
- (a) doesn't pass through it, so it stays cold.
- If all 5 consumers used *different* filters, the only shared node is the source → cache `df`.

**River/dam analogy:** build the dam **just before the river splits**. Every branch downstream
is served while you hold the least water. A dam at the source serves everyone but holds
everything; a dam on one branch serves only that branch.

## Why size is a COST, not a benefit
```
value ≈ (work saved per hit × hits) − (memory spent)
```
- 50 GB cache vs 0.5 GB cache, both used 5× by the same queries → **identical speedup**,
  100× the memory. The extra 49.5 GB holds rows nobody reads.
- **Photocopy analogy:** 5 people need page 10 of a 1,000-page manual. Copying the whole
  manual helps them exactly as much as copying page 10 — for 1,000× the paper.

## Eviction and spill — why an oversized cache is worse than none
| Word | Simple meaning | Cost |
|---|---|---|
| **spill** | move data to disk to free RAM | extra write + extra read |
| **evict** | drop it from memory entirely | must be **recomputed from lineage** |

Desk analogy: your desk holds 16 folders; you ask to keep 50. The overflow goes back to the
cabinet, and to make room Spark keeps throwing folders off the desk — possibly the one you
need next.

```python
# without cache
read 50 GB → work → done                      # 1x

# oversized cache
read 50 GB → try to store → spill some
          → read spilled data back
          → find evicted parts → recompute     # 2–3x
```
You paid for RAM and still did the reading.

> **The best cache is the one that fits.**

## Decision checklist before caching
1. Will this result be **used more than once**? (more than one action, or more than one branch)
2. Is it the **lowest common ancestor** of those uses?
3. Does it **fit** comfortably in memory?
4. Is the recomputation actually **expensive** (big scan, heavy join)?

Four yeses → cache. Otherwise skip it.

## Interview line
> "I cache at the lowest common ancestor of all consumers, when it fits in memory and avoids
> expensive recomputation. Size isn't the goal — hit rate is, and an oversized cache spills
> and evicts, which is worse than no cache."
