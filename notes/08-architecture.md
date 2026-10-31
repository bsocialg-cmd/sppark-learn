# Note 08 — Architecture I: the cast

> **Level:** absolute beginner. Every word is defined before it is used.
> **Status:** Part I complete. Part II (job → stage → task, lineage) comes next.

---

## 1. The situation

You have a spreadsheet with **300 million rows** of sales.

Your laptop has 16 GB of memory. The file does not fit. You cannot open it.

So you rent **3 computers** instead of using 1.

Now three things must happen:

1. **Cut** the data into chunks — one chunk per computer
2. **Work** on the chunks at the same time
3. **Gather** the answers back together

Spark is the software that does all three.

---

## 2. The three jobs

| Job | What it means in plain words | Who it is |
|---|---|---|
| **Plan the work** | Reads *your* code, decides the steps, hands out jobs, collects the results | **Driver** |
| **Do the work** | Holds a chunk of data in memory and processes it | **Executor** |
| **Provide the computers** | Decides which machines Spark may use | **Cluster manager** |

### The restaurant picture

```
   customer order   =  your code
   head chef        =  driver          (plans, shouts orders, never cooks)
   line cooks       =  executors       (actually cook)
   landlord         =  cluster manager (gives you the kitchen)
```

**Rule 1:** the head chef does not cook.
**Rule 2:** the line cooks do not plan.

In Spark: **the driver never touches the data. The executors never decide anything.**

---

## 3. The work units

| Word | Plain meaning | Restaurant |
|---|---|---|
| **Partition** | one chunk of the data | one tray of ingredients |
| **Task** | the work of processing **one** partition | one dish |
| **Core** | one processor. It does **one task at a time** | one stove |

So the chain is always:

```
1 partition  →  1 task  →  1 core at a time
```

---

## 4. A concrete example

- 300 million rows
- 3 computers × 4 cores each = **12 cores**
- Spark cuts the data into **12 partitions**

```
        DRIVER  "12 tasks, go"
              │
   ┌──────────┼──────────┐
   ▼          ▼          ▼
COMPUTER 1  COMPUTER 2  COMPUTER 3
4 cores     4 cores     4 cores
[4 tasks]   [4 tasks]   [4 tasks]
```

12 tasks, 12 cores → **all run at the same time. One round.**

Now change one number: only **3 partitions**.

```
3 tasks, 12 cores → 3 cores work, 9 cores sit idle
```

The job takes about **4 times longer** than it needed to. Nothing is broken — it is just
wasting the computers you are paying for.

That single idea is called **parallelism**: how much work happens at the same time.

---

## 5. What happens when you run `df.show()`

Step by step:

1. **Driver** reads your code and builds a plan
2. **Driver** sends tasks to the executors
3. **Executors** process their partitions and send the answers back
4. **Driver** shows you the result

Every **action** (`show`, `count`, `write`) follows this path.

Every **transformation** (`filter`, `select`, `withColumn`) only edits the plan.
No data moves, no tasks run.

---

## 6. Two consequences you can now predict

| Situation | What happens | Why |
|---|---|---|
| `df.collect()` on 300M rows | the driver may run out of memory and crash | every row is shipped to the driver, which has limited memory |
| 3 partitions on 12 cores | 9 cores idle | concurrency = `min(partitions, cores)` |

---

## 7. Where does the driver live? (deployment modes)

| Mode | Driver lives... | Used for |
|---|---|---|
| **`local[*]`** | on your laptop, executors in the **same** program | learning, small data |
| **Standalone** | inside the cluster | simple clusters |
| **YARN** | on a cluster node | Hadoop shops |
| **Kubernetes** | in a container pod | cloud-native setups |
| **Databricks serverless** | managed for you; executors are created per query and then destroyed | your current setup |

**Why this matters:** `local[*]` is enough to learn, because the cast is identical — it is
just all inside one building.

**Databricks serverless specifics:** executors are temporary. `spark.sparkContext` and RDDs
are blocked, and the Storage tab may be missing. That is a *platform* rule, not a Spark rule.

---

## 8. Words used in this note

| Word | Meaning |
|---|---|
| **Cluster** | a group of computers working as one system |
| **Node** | one computer inside the cluster |
| **Driver** | the program running your code; plans and coordinates |
| **Executor** | a process on a worker computer; holds data and does the work |
| **Cluster manager** | software that assigns machines (YARN, Kubernetes, Standalone) |
| **Partition** | one chunk of the data |
| **Task** | the work of processing one partition |
| **Core** | one processor; runs one task at a time |
| **Job** | all the work triggered by one action |
| **Action** | something that asks for a result (`show`, `count`, `write`) |
| **Transformation** | something that only describes a change (`filter`, `select`) |

---

## 9. Check questions (still open)

1. **Who actually processes the 300 million rows — the driver or the executors?**
2. **What does the driver do all day?**

---

## 10. Next: Architecture II
- How one action becomes **job → stage → task**
- **Narrow vs wide dependencies** — why a shuffle creates a new stage
- **Lineage** — what happens when an executor dies mid-job
- Hands-on: trace one query through every layer using `explain()`
