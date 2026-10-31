# Note 04 — How to read a physical plan (`explain()`)

## Why bother
`explain()` is Spark's **X-ray**. It tells you what Spark *actually* plans to do —
which is often not what you assumed.

## Rule: read it **bottom-up**
Data flows from the bottom of the plan to the top. The bottom is the source; the top is the result.

## Example (Databricks / Photon)
```
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- PhotonResultStage
   +- PhotonColumnarToRow
      +- PhotonGroupingAgg(keys=[_groupingexpression], functions=[finalmerge_count(...)])
         +- PhotonShuffleExchangeSource false
            +- PhotonShuffleMapStage ENSURE_REQUIREMENTS
               +- PhotonShuffleExchangeSink hashpartitioning(_groupingexpression, 16)
                  +- PhotonGroupingAgg(keys=[...], functions=[partial_count(1)])
                     +- PhotonProject [(id % 10) AS _groupingexpression]
                        +- PhotonRange Range (0, 1000, step=1, splits=8)
```

| Line (bottom-up) | Plain meaning |
|---|---|
| `Range (..., splits=8)` | generate the data in **8 partitions** |
| `Project [(id % 10)]` | compute the grouping key |
| `GroupingAgg(partial_count)` | count rows **within each partition, before moving data** |
| `ShuffleExchangeSink hashpartitioning(..., 16)` | shuffle into **16 partitions** |
| `ShuffleMapStage` | **stage boundary** — this is where stage 1 ends |
| `ShuffleExchangeSource` | read the shuffled data (stage 2 starts) |
| `GroupingAgg(finalmerge_count)` | add the partial counts together |
| `ColumnarToRow` | convert internal columnar format to rows for output |
| `AdaptiveSparkPlan isFinalPlan=false` | AQE will re-optimise when it runs |

## Words you must recognise
| Word | Meaning |
|---|---|
| `Exchange` | **shuffle**. Expensive. Find these first. |
| `hashpartitioning(col, N)` | shuffle by hash of a column into N partitions |
| `splits=N` | how many partitions the source produced |
| `Project` | selecting / computing columns |
| `Filter` | filtering rows |
| `partial_*` | aggregation before the shuffle |
| `finalmerge_*` | aggregation after the shuffle |
| `BroadcastHashJoin` | small table copied to every executor (good, no shuffle) |
| `SortMergeJoin` | both sides shuffled and sorted (expensive) |
| `Photon` | Databricks' vectorised C++ engine — **not** part of OSS Spark |

## Key insight for beginners
A plan is a **tree of steps**, and a **stage boundary** appears at every `Exchange` (shuffle).
Two stages = two rounds of tasks, and the second one waits for the first to finish writing
its shuffle files.

## How to practice
Run a query, call `.explain()`, and answer:
1. Where is the `Exchange`? → that's the expensive part
2. How many partitions on each side of it? → `splits=` and `(N)`
3. What got pushed down? → look for `Filter` right next to the scan
