# Databricks notebook source
# MAGIC %md
# MAGIC # Spark Course — Lesson 1
# MAGIC **Why Spark Exists & How It Thinks**
# MAGIC
# MAGIC Work through the cells top to bottom. Type the code yourself where you can.
# MAGIC Answer the questions in the markdown cells at the end.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 0. Verify the environment
# MAGIC Note: on Databricks the `spark` session already exists. Never create a new one.

# COMMAND ----------

print("Spark version:", spark.version)
spark.range(5).show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Lazy evaluation
# MAGIC Transforming does nothing. Only an *action* triggers work.

# COMMAND ----------

from pyspark.sql import functions as F

data = [
    ("alice", "books",  120.0),
    ("bob",   "books",   45.0),
    ("alice", "games",  300.0),
    ("carol", "games",   75.0),
]

df = spark.createDataFrame(data, "customer string, category string, amount double")

# lazy chain: NOTHING has run yet
big = df.filter(df.amount > 50).select("customer", "category", "amount")

# action: now it runs
display(big)

# COMMAND ----------

# The plan Catalyst built for the above query
big.explain()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Exercise — DataFrame API
# MAGIC Data: `[("w1", 5), ("w2", 12), ("w1", 7), ("w3", 20), ("w2", 3)]`
# MAGIC
# MAGIC 1. Build a DataFrame with an explicit schema string: `week string, units int`
# MAGIC 2. Filter `units > 4` and display it
# MAGIC 3. Group by `week`, sum `units`, order by the sum descending, display
# MAGIC
# MAGIC Write it below — don't scroll past until it works.

# COMMAND ----------

# your code here

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Exercise — same thing in SQL

# COMMAND ----------

# your code here
# hint: createOrReplaceTempView("units"), then spark.sql("...")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Experiment
# MAGIC Remove the `display()` from the filter step. Does anything run?
# MAGIC How can you tell? Write your answer here.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Quiz (answer in this cell)
# MAGIC 1. `df.filter(...)` — does it process data? Why not?
# MAGIC 2. Name one thing the optimizer can do because evaluation is lazy.
# MAGIC 3. Driver vs executor, one sentence each.
# MAGIC 4. 8 cores, 200 partitions — how many run at once, and roughly how many waves?
# MAGIC 5. One transformation and one action from memory.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. In your own words
# MAGIC Write 3 sentences: what is a partition, and why does the number matter?

# COMMAND ----------


