# Note 02 — `coalesce` vs `repartition`

Both change **how many partitions** your data has. They do it in completely different ways,
which is why one is cheap and one is expensive.

## The analogy
- **coalesce** = "merge rooms, don't move furniture." Rooms 1+2 become one room. Nothing is
  physically moved; one worker now walks through both.
- **repartition** = "empty every room, re-deal all items evenly into new rooms." Balanced,
  but everything gets carried across the building (= network shuffle).

---

## coalesce(n) — merge, no shuffle

```
before:  [P1][P2][P3][P4][P5][P6]     (6 partitions)
coalesce(2)

after:   [P1 P2 P3][P4 P5 P6]          (2 partitions)
```

- Only **reduces** the count.
- **No data moves.** Each new task simply reads several existing partitions.
- Narrow dependency → no new stage → very cheap.
- **Risk:** imbalance. With skew, one merged partition can be huge.

```python
df.coalesce(2).explain()
# Coalesce 2          <- no Exchange, no shuffle
```

---

## repartition(n) — full shuffle

```
before:  [P1][P2][P3][P4]              (4 partitions)
repartition(6)

        ╲  all rows move across the network  ╱

after:   [p1][p2][p3][p4][p5][p6]      (6 partitions, evenly sized)
```

- Can go **up or down**.
- Writes every row to disk/network and re-reads it → expensive (`Exchange`).
- Result is **evenly balanced** (round-robin by default).
- `repartition(6, "customer_id")` → hash-partitions by that column (useful before joins).

```python
df.repartition(6).explain()
# Exchange RoundRobinPartitioning(6)   <- shuffle stage
```

---

## Side by side

| | `coalesce(n)` | `repartition(n)` |
|---|---|---|
| Direction | decrease only | increase or decrease |
| Data movement | **none** | **full shuffle** (network + disk) |
| New stage | no | yes |
| Cost | cheap | expensive |
| Balance | can be uneven | even |
| Partition by column | no | yes (`repartition(n, "col")`) |
| Typical use | reduce files before write, shrink after filtering | raise parallelism, fix skew, pre-join |

---

## Why can't coalesce increase?
Because splitting an existing chunk into two requires redistributing rows — that *is* a shuffle.
Spark only implements the merge direction for the cheap path. `coalesce(50)` on 4 partitions
returns the same 4 partitions (no-op).

---

## Your case: 4 partitions → 6 cores

```python
df.repartition(6)   # works, but pays a full shuffle
df.coalesce(6)      # NO-OP, still 4 partitions
```

Better target: **12–24 partitions** (2–4 per core), and only if the data is big enough that
the shuffle cost < the time saved by using all cores.

---

## Practical rules
1. **After a big filter** (1000 partitions → 1% of data): `coalesce(...)` to avoid empty/tiny tasks.
2. **Before writing files**: `coalesce(k)` to control output file count. Avoid `coalesce(1)` on
   large data — everything lands on one task (OOM risk), and it kills parallelism.
3. **Need more parallelism**: `repartition(n)`, only on large data.
4. **Before a join**: `repartition(n, "join_key")` can co-locate matching rows and avoid a later shuffle.
5. Modern Spark **AQE** auto-coalesces small shuffle partitions after a `groupBy`/`join`
   (`spark.sql.adaptive.enabled`), so manual tuning is needed less often than in old tutorials.

## Lab
```python
df = spark.range(10_000_000)

df.repartition(6).explain()   # look for Exchange
df.coalesce(2).explain()      # look for Coalesce, no Exchange
df.coalesce(50).explain()     # no-op if it already has fewer partitions
```
