# Note 08 — Architecture I: the cast

> Level: absolute beginner. Every term defined here.
> Status: **Part I complete.** Part II (job → stage → task, lineage) is next session.

---

## 1. The problem architecture solves

You have a table with **1 billion rows**. Your laptop has 16 GB of memory. It does not fit.

So you rent **3 computers**:

- The data is **split** into pieces, one per computer
- Each computer works on **its own piece**
- Something has to **coordinate**: decide who does what, then gather the answers

Spark is the software that does the splitting, the coordinating, and the gathering.

---

## 2. The three roles

| Role | Plain definition | Restaurant analogy |
|---|---|---|
| **Driver** | The program that runs **your code**. It reads your instructions, builds a plan, and hands out work. **It never processes data.** | Head chef: reads the order, writes the plan, shouts instructions |
| **Executor** | A process on a worker computer. It **holds data in memory and does the actual processing**. | Line cook: chops, fries, plates |
| **Cluster manager** | Software that decides **which computers** Spark may use. Examples: Standalone, YARN, Kubernetes. | Landlord: assigns kitchens |

Two rules that explain almost every Spark behaviour:

1. **The driver never touches the data.** It only plans, schedules, and collects results.
2. **Executors never plan.** They do exactly what they are told.

---

## 3. The smaller pieces

| Term | Plain definition | Analogy |
|---|---|---|
| **Cluster** | A group of computers working together as one system. | A restaurant with several kitchens |
| **Node** | One computer inside the cluster. | One kitchen |
| **Core** | One processor inside a machine. One core runs **one task at a time**. | One stove |
| **Task** | The work of processing **one partition**. | One dish |
| **Partition** | One chunk of the data. Data is always split into partitions. | One portion of ingredients |
| **Job** | All the work triggered by **one action** (`show`, `count`, `write`). | One customer order |
| **Stage** | A group of tasks with no data movement between them. A job is cut into stages at every shuffle. | A cooking phase |

---

## 4. The picture

```
   YOUR CODE  ("read the file, add up the amounts")
        │
        ▼
   DRIVER  ──── builds the plan ────►  "you 3, each take one piece"
        │                                    │
        │                          ┌─────────┼─────────┐
        │                          ▼         ▼         ▼
        │                     EXECUTOR 1  EXECUTOR 2  EXECUTOR 3
        │                     (piece 1)   (piece 2)   (piece 3)
        │                          │         │         │
        └────── collects ◄─────────┴─────────┴─────────┘
                the answers
```

---

## 5. Where does the driver run? (deployment modes)

| Mode | Driver lives... | Used for |
|---|---|---|
| **`local[*]`** | on your laptop, executors in the **same** process | learning, small data |
| **Standalone** | inside the cluster | simple clusters |
| **YARN** | on a cluster node | Hadoop shops |
| **Kubernetes** | in a pod | cloud-native |
| **Databricks serverless** | managed for you; executors are created per query and destroyed | your current setup |

**Why this matters:** `local[*]` is enough to learn, because the *cast is identical* — it's just
all in one building.

**Databricks serverless specifics:** executors are ephemeral, `spark.sparkContext` and RDDs are
blocked, and the Storage tab may be unavailable. That is a platform restriction, not a Spark one.

---

## 6. Consequences you can already predict

| If you... | Then... | Why |
|---|---|---|
| call `collect()` on a huge DataFrame | driver may run out of memory | all rows are shipped to the driver |
| have 3 partitions on 8 cores | 5 cores idle | concurrency = `min(partitions, cores)` |
| call `show()` | a job starts | `show` is an action |
| call `filter()` | nothing happens | transformation, only extends the plan |

---

## 7. Check questions (still unanswered)

1. **Who holds the data while it's being processed — the driver or the executors?**
2. **What is the driver's job, in your own words?**

---

## 8. Next: Architecture II
- How one action becomes **job → stages → tasks**
- **Narrow vs wide dependencies** (why shuffles create stage boundaries)
- **Lineage** and fault tolerance: what happens when an executor dies
- Hands-on: trace one query through every layer using `explain()`
