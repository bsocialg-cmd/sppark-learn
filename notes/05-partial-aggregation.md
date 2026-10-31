# Note 05 — Partial aggregation (`partial_count`)

## The problem
`df.groupBy("customer").count()` on 10 million rows.
A naive engine would move **all 10 million rows** across the network before counting.

You don't need every row on the far side — you need the **subtotals**.

## What Spark does instead: count first, move second

```
  PARTITION 1          PARTITION 2          PARTITION 3
  A A A B              A B B B              A A C
      │                    │                    │
  partial_count        partial_count        partial_count
  (A,3) (B,1)          (A,1) (B,3)          (A,2) (C,1)
      └────────────────────┼────────────────────┘
                     SHUFFLE  (8 rows, not 12)
                           │
                  finalmerge_count
              A = 3+1+2 = 6
              B = 1+3   = 4
              C = 1     = 1
```

| Phase | Name in the plan | What it does |
|---|---|---|
| 1. before the shuffle | `partial_count` | count rows **within one partition** |
| 2. after the shuffle | `finalmerge_count` | add the partial counts |

The `partial_` prefix means: *"not the final answer — a piece that must be merged."*

## Why the saving is huge
10,000,000 rows · 200 partitions · 1,000 customers:

| Approach | Rows crossing the network |
|---|---|
| no partial aggregation | 10,000,000 |
| with `partial_count` | ≤ 200 × 1,000 = **200,000** |

**50x less network traffic, same answer.** Collapse rows *before* you move them.

## When it does nothing
If the grouping key is (nearly) unique per row, nothing collapses:

```python
df.groupBy("id").count()     # id is unique → every row is its own group
```
Each partition emits as many partial rows as it consumed → **zero reduction** → full shuffle.

This is why grouping by a high-cardinality key, or `distinct` on a unique column, is expensive.

## Why the maths is allowed
`count`, `sum`, `min`, `max` are **associative**:
`(3 + 1) + 2 == 3 + (1 + 2)`

`avg` isn't, so Spark rewrites it as `partial_sum` + `partial_count` and divides at the end.
That's why one `avg` shows up as two functions in the plan.

## Interview line
> "`groupBy` uses map-side partial aggregation, so only one row per (partition, group) is
> shuffled. The benefit scales with how much the key collapses — grouping by a unique ID
> collapses nothing and shuffles everything."
