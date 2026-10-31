# Note 09 — How `groupBy` works

## The starting problem
Rows with the same key live on **different partitions**, so they cannot be counted together
until they are moved. That move is the **shuffle**.

```
partition 1:  A  A  B
partition 2:  B  C  C
partition 3:  A  C
```

## Step 1 — count locally (map side)
Each partition aggregates its **own** rows first.

```
partition 1:  A A B   →  (A,2) (B,1)
partition 2:  B C C   →  (B,1) (C,2)
partition 3:  A C     →  (A,1) (C,1)
```

12 rows become 8 small pairs. In the plan this is `partial_count`.
**This is the step that makes `groupBy` affordable** — only one row per (partition, key) travels.

## Step 2 — hash the key to choose a destination
```
hash(A) % 4 = 0
hash(B) % 4 = 1
hash(C) % 4 = 2
```
The **same key always maps to the same number**, so all `A` rows land in the same output
partition regardless of where they started. (Coat-check ticket analogy.)

```
(A,2) (A,1) → box 0
(B,1) (B,1) → box 1
(C,2) (C,1) → box 2
box 3       → empty
```

## Step 3 — merge (reduce side)
```
box 0: A = 2+1 = 3
box 1: B = 1+1 = 2
box 2: C = 2+1 = 3
```
In the plan: `finalmerge_count`.

## The pipeline
```
STAGE 1   read → partial count
              ║
              ║  SHUFFLE (write to disk + network)
              ║  BARRIER — stage 2 waits
STAGE 2   read boxes → merge → result
```

## Consequences
| Fact | Why |
|---|---|
| Empty boxes still cost a task | partition count is fixed by config, not by keys present |
| 200 shuffle partitions on tiny data → ~195 empty tasks | `spark.sql.shuffle.partitions` is a fixed number |
| `groupBy("id")` (unique key) is very expensive | nothing collapses; every row is its own group |
| `groupBy("country")` is cheap | few groups → heavy collapse before the shuffle |

## One-liner
> `groupBy` = count locally → send each key to a fixed box by hash → merge the boxes.
> The middle step is a shuffle, which is why it is a wide transformation with a stage barrier.
