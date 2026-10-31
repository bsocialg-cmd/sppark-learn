# Lesson 2 — How Spark Works: Architecture

**Level:** complete beginner · **Time:** 45–60 min · **Prerequisites:** none

## What you will be able to do

By the end of this lesson you can:
1. Explain what a **driver**, an **executor** and a **cluster manager** do.
2. Explain what a **partition**, a **task** and a **core** are, and how they relate.
3. Predict how long a job takes from the number of partitions and cores.
4. Trace what happens, step by step, when you call `df.show()`.

---

## Words you will meet (nothing assumed)

| Word | Meaning, in one line |
|---|---|
| **Data** | Information in rows and columns — like a spreadsheet |
| **Cluster** | A group of computers working together as one system |
| **Node** | One computer inside a cluster |
| **Driver** | The program that runs *your* code and plans the work |
| **Executor** | A program on a worker computer that does the actual processing |
| **Cluster manager** | Software that decides which computers Spark may use |
| **Partition** | One chunk of the data |
| **Task** | The work of processing one partition |
| **Core** | One processor; it runs one task at a time |
| **Action** | Something that asks for a result: `show`, `count`, `write` |
| **Transformation** | Something that only describes a change: `filter`, `select` |

---

## Part 1 — The problem

You have a spreadsheet with **300 million rows** of sales data.

Your laptop has 16 GB of memory. The file does not fit. You cannot even open it.

You have two choices:

1. **Buy a bigger computer.** Expensive, and one day the data gets bigger again.
2. **Use several ordinary computers at once.** Cheap, and it scales forever.

Spark chooses option 2. And that choice creates three jobs that must be done:

- **Cut** the data into manageable chunks
- **Work** on the chunks at the same time
- **Gather** the results back together

Everything in this lesson is about *who does those three jobs*.

---

## Part 2 — The three jobs (and the people who do them)

| Job | Who does it | What it means |
|---|---|---|
| Plan and coordinate | **Driver** | Reads your code, builds a plan, hands out work, collects results |
| Do the actual work | **Executor** | Holds a chunk of data in memory and processes it |
| Supply the computers | **Cluster manager** | Decides which machines Spark gets to use |

### The restaurant picture 🍽️

```
   the customer's order   =   your code
   the head chef          =   driver           (plans, shouts orders, never cooks)
   the line cooks         =   executors        (chop, fry, plate)
   the landlord           =   cluster manager  (gives you the kitchen)
```

Two rules follow, and they explain almost everything later in the course:

> **Rule 1 — The head chef does not cook.**
> The driver never processes the data.
>
> **Rule 2 — The line cooks do not plan.**
> Executors never decide anything. They do exactly what they are told.

### Why this matters

When something is slow, the first question is always: *is the driver the bottleneck, or the executors?*
- Driver bottleneck → you asked it to hold data (e.g. `collect()`)
- Executor bottleneck → too few partitions, or too little memory

---

## Part 3 — The work units

Spark cannot give "300 million rows" to one worker. It **cuts the data into partitions**.

| Word | Meaning | Restaurant |
|---|---|---|
| **Partition** | one chunk of the data | one tray of ingredients |
| **Task** | the work of processing one partition | one dish |
| **Core** | one processor; does one task at a time | one stove |

The chain is always the same:

```
one partition  →  one task  →  one core at a time
```

**The relay-race picture 🏃**
Twelve runners (cores), twelve batons (tasks). Everyone runs at once and the race finishes in
one round. But if you only have three batons (three partitions), nine runners stand and watch.

### The one formula to remember

```
tasks running at the same time  =  min( partitions , cores )
```

- **Too few partitions** → some cores sit idle. You are paying for computers that do nothing.
- **Too many partitions** → each task is tiny, and the fixed cost of starting a task is bigger
  than the work itself.

Think of it as: *enough trays for every stove, but not so many that the cook spends all day
walking back and forth.*

---

## Part 4 — One action, step by step

You type:

```python
df.show()
```

What actually happens:

```
1. DRIVER reads your code
        │
2. DRIVER builds a plan ("read the file, filter, group, show")
        │
3. DRIVER splits the plan into stages and tasks
        │
4. DRIVER sends tasks to the EXECUTORS
        │
5. EXECUTORS read their partitions, do the work, send answers back
        │
6. DRIVER collects the answers and shows them to you
```

Now compare with a transformation:

```python
df.filter(F.col("amount") > 100)
```

Nothing on that list happens. Not one step. The driver only writes down an instruction for later.
The work starts at **step 1** only when an action arrives.

> **Action = start the engine. Transformation = add a note to the plan.**

---

## Part 5 — Where does the driver live?

| Mode | Driver lives… | Used for |
|---|---|---|
| `local[*]` | on your laptop, executors in the same program | learning, small data |
| **Standalone** | inside the cluster | simple clusters |
| **YARN** | on a cluster node | Hadoop shops |
| **Kubernetes** | in a container pod | cloud-native setups |
| **Databricks serverless** | managed for you; executors are created and destroyed per query | your setup |

`local[*]` is enough to learn, because the cast is identical — the whole restaurant is just
inside one building.

In your Databricks sandbox: the driver is managed, executors are temporary, and some commands
(`df.rdd`, `spark.sparkContext`) are blocked. That is a **platform** rule, not a Spark rule.

---

## Part 6 — What architecture lets you predict

| If you… | Then… | Because |
|---|---|---|
| call `collect()` on 300M rows | the driver may crash | every row is shipped to the driver |
| have 3 partitions on 12 cores | 9 cores idle, ~4x slower | `min(3, 12) = 3` |
| call `show()` | a job starts | it is an action |
| call `filter()` | nothing happens | it is a transformation |
| lose one executor mid-job | the job continues | tasks are recomputed on another executor |

---

## Part 7 — Exercises (do these, don't just read)

**Exercise 1 — draw it**
Draw your own Databricks setup: one driver box, one executor box, and label the parts.
Put the words *driver, executor, core, task, partition* on the drawing.

**Exercise 2 — the maths**
A job has **20 partitions** and the cluster has **8 cores**.
1. How many tasks are created?
2. How many run at the same time?
3. How many rounds ("waves")?
4. Roughly how much faster would it be with 4 partitions instead of 20? *(careful — think)*

**Exercise 3 — who does what**
For each, say whether it is **driver work** or **executor work**:
- reading a Parquet file
- deciding how many tasks to create
- summing numbers inside one partition
- printing the result to your screen

**Exercise 4 — read a real plan**
In Databricks run:
```python
spark.range(1000).groupBy((F.col("id") % 10).alias("g")).count().explain()
```
Find `splits=`. What does the number mean? Can you find the word `Exchange`?

---

## Part 8 — Checkpoint (answer out loud, in your own words)

1. Who processes the data — driver or executors?
2. What does the driver do all day?
3. What is a partition, and why does the number matter?
4. 6 partitions on 12 cores — is anything wasted?
5. Which one starts the work: `filter` or `count`?

---

## Part 9 — Summary card

```
DRIVER      plans, schedules, collects      (never touches data)
EXECUTORS   hold partitions, do the work    (never plan)
CLUSTER MGR gives out the machines

partition → task → one core at a time
concurrency = min(partitions, cores)

action        → starts a job
transformation → only edits the plan
```

**Next lesson:** how one action becomes **jobs → stages → tasks**, and why a shuffle splits a job
into stages (Architecture II).
