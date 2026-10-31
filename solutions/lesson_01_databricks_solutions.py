# Databricks notebook source
# MAGIC %md
# MAGIC # Lesson 1 — Solutions & Syntax Walkthrough
# MAGIC
# MAGIC **How to use this:** read a cell, then **cover it and retype it from memory** in your own
# MAGIC notebook. Reading code teaches you nothing; retyping it builds muscle memory.
# MAGIC
# MAGIC Every solution has a "why" comment. Those matter more than the code.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup — the one import you always need
# MAGIC `F` is just an alias. Spark does not create it for you. Type this at the top of every notebook.

# COMMAND ----------

from pyspark.sql import functions as F

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exercise 1 & 2 — build a DataFrame with an explicit schema
# MAGIC
# MAGIC **Syntax rule:** a schema string is `"col_name TYPE, col_name TYPE"`.
# MAGIC Common types: `string`, `int`, `long`, `double`, `boolean`, `date`, `timestamp`.
# MAGIC
# MAGIC **Syntax rule:** `createDataFrame()` wants a *list of tuples*, one tuple per row,
# MAGIC in the same order as the columns.

# COMMAND ----------

data = [
    ("w1", 5),
    ("w2", 12),
    ("w1", 7),
    ("w3", 20),
    ("w2", 3),
]

df = spark.createDataFrame(data, schema="week string, units int")

df.printSchema()   # always confirm the types — "5" as string breaks sums silently
display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exercise 3 — filter `units > 4`
# MAGIC
# MAGIC Two equivalent syntaxes. Prefer `F.col()`:
# MAGIC - `df.units` works but breaks if a column name is also a DataFrame method (e.g. `count`, `filter`).
# MAGIC - `F.col("units")` is always safe.
# MAGIC
# MAGIC ⚠️ Filtering is **lazy** — nothing runs until `display()` / `show()`.

# COMMAND ----------

filtered = df.filter(F.col("units") > 4)
display(filtered)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exercise 4 — group, sum, order descending
# MAGIC
# MAGIC **Syntax rule:** `groupBy("key").agg(F.sum("value").alias("new_name"))`
# MAGIC - `.agg()` wraps every aggregation.
# MAGIC - `.alias()` is **required** — otherwise the column is literally named `sum(units)`.
# MAGIC
# MAGIC **Syntax rule:** descending = `F.desc("col")` or `F.col("col").desc()`.

# COMMAND ----------

totals = (
    df.groupBy("week")
      .agg(F.sum("units").alias("total_units"))
      .orderBy(F.desc("total_units"))
)

display(totals)

# Expected:
# w3 20
# w2 15
# w1 12

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exercise 5 — the same thing in SQL
# MAGIC
# MAGIC **Syntax rule:** a temp view is a name you lend to a DataFrame so SQL can see it.
# MAGIC It lives for the session only. Use `createOrReplace` so reruns don't fail.

# COMMAND ----------

df.createOrReplaceTempView("units")

display(spark.sql("""
    SELECT week,
           SUM(units) AS total_units
    FROM   units
    GROUP  BY week
    ORDER  BY total_units DESC
"""))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exercise 6 — the experiment: what does removing `display()` prove?
# MAGIC
# MAGIC **Answer:** nothing runs. `filter()` only *records an instruction*.
# MAGIC
# MAGIC How you know:
# MAGIC 1. It returns instantly even on a huge DataFrame.
# MAGIC 2. In Spark UI → **Jobs**, the count does not increase.
# MAGIC 3. `filtered.explain()` shows a plan, but no job has executed.
# MAGIC
# MAGIC `explain()` is free — it just prints the plan. `display()`, `count()`, `collect()` cost time.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exercise 7 — what is a partition?
# MAGIC
# MAGIC **Model answer:**
# MAGIC > A partition is one chunk of a DataFrame's data. Spark processes one partition per task,
# MAGIC > and each CPU core runs one task at a time, so the partition count caps parallelism.
# MAGIC > Too few partitions leaves cores idle (wasted time and money); too many creates
# MAGIC > thousands of tiny tasks where scheduling overhead exceeds the actual work.
# MAGIC > I aim for roughly 100–200 MB per partition, or 2–4 tasks per core.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Quiz answers
# MAGIC
# MAGIC **1. Does `df.filter(...)` process data?**
# MAGIC No. It is a *transformation* — lazy. It only extends the query plan.
# MAGIC
# MAGIC **2. One thing the optimizer can do because of laziness?**
# MAGIC Predicate pushdown (read fewer rows), column pruning (read fewer columns),
# MAGIC or combining filters into one scan.
# MAGIC
# MAGIC **3. Driver vs executor?**
# MAGIC Driver: runs your program, builds/optimizes the plan, schedules tasks, collects results.
# MAGIC Executor: runs tasks on partitions and holds cached data.
# MAGIC
# MAGIC **4. 8 cores, 200 partitions?**
# MAGIC `MIN(200, 8)` = 8 tasks at once → 200/8 = **25 waves**.
# MAGIC
# MAGIC **5. One transformation, one action?**
# MAGIC Transformation: `filter`, `select`, `groupBy`. Action: `count`, `show`, `write`.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Self-test: change one thing
# MAGIC Don't move on until you can predict these without running them:
# MAGIC
# MAGIC 1. What does `df.filter(F.col("units") == 5).count()` return? → **1**
# MAGIC 2. What does `df.groupBy("week").count()` return? → count of **rows** per week, not sum
# MAGIC 3. What does `totals.orderBy("total_units").show()` order by? → **ascending** (default)
# MAGIC 4. If I `filter` then `groupBy`, which happens first? → **filter** (Spark pushes it down)

# COMMAND ----------

spark.stop()
