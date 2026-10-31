# Note 07 — Functions Primer (beginner)

**The big idea:** a DataFrame is a **spreadsheet with superpowers**.
- Rows = records (one per transaction/customer/order).
- Columns = fields.
- Every Spark function **takes a DataFrame (or a column) and returns a new one**.
  Nothing is edited in place. Like a photocopier: you feed a page in, you get a new page out.

---

## 1. How to READ any PySpark line

```python
df.filter(F.col("amount") > 100).select("customer")
```

Read it left to right, like a conveyor belt:

| Piece | Meaning |
|---|---|
| `df` | the table you start with |
| `.filter(...)` | a station on the belt: "keep only these rows" |
| `(...)` | the instructions you hand to that station |
| `F.col("amount")` | the **column** called amount (not the data — a reference to the column) |
| `> 100` | a comparison applied to that column, row by row |
| `.select("customer")` | next station: "keep only this column" |

**Rules of thumb**
- `.something(...)` = "do this to the thing on the left, with these instructions".
- Chaining means: output of one station feeds the next. Order matters.
- Nothing runs until an **action** (`show`, `count`, `display`, `write`).

## 2. `F.col()` — what is F?

```python
from pyspark.sql import functions as F
F.col("amount")     # "the amount column"
```
`F` = "functions". It's a toolbox. `F.col` is one tool in it.
You need it whenever you want to **do math or compare a column**:
```python
F.col("price") * F.col("qty")
F.col("amount") > 100
F.col("name").isNull()
```

---

## 3. Reading data

```python
df = spark.read.csv("path.csv", header=True, inferSchema=True)
df = spark.read.parquet("path/")
df = spark.read.json("path.json")

df = spark.read.csv("p.csv", header=True, schema="id int, name string, amount double")
```
| Function | Plain meaning |
|---|---|
| `header=True` | first row is column names, not data |
| `inferSchema=True` | Spark guesses types (slow, can guess wrong) |
| `schema="..."` | you state the types (fast, safe) |

**Analogy:** `header` = the labels on the filing cabinet; `schema` = the label telling you
"this drawer holds numbers, not text".

---

## 4. Looking at data (all actions except the first three)

```python
df.show(5)          # print first 5 rows (default 20)
df.printSchema()    # column names + types (metadata, no data read)
df.columns          # list of column names
df.count()          # number of rows
display(df)         # Databricks: pretty table + charts
```

---

## 5. Choosing columns

| Function | Plain meaning | Example |
|---|---|---|
| `select` | keep these columns | `df.select("id", "name")` |
| `drop` | remove these columns | `df.drop("internal_flag")` |
| `withColumn` | add or replace a column | `df.withColumn("total", F.col("p") * F.col("q"))` |
| `withColumnRenamed` | rename one | `df.withColumnRenamed("amt", "amount")` |
| `cast` | change a type | `df.withColumn("amount", F.col("amount").cast("double"))` |

**Analogy:** `select` = choosing which pages to photocopy. `withColumn` = adding a new
calculated column in a spreadsheet (like column E = B*C).

---

## 6. Filtering rows

```python
df.filter(F.col("amount") > 100)
df.filter((F.col("country") == "US") & (F.col("amount") > 100))   # AND
df.filter((F.col("country") == "US") | (F.col("country") == "CA")) # OR
df.filter(F.col("country").isin("US", "CA", "MX"))
df.filter(F.col("name").isNull())
df.filter(F.col("name").isNotNull())
```
⚠️ Because `&`/`|` bind tighter than `>`, **wrap each condition in its own parentheses**.
⚠️ Never use Python's `and`/`or` here — they don't work on columns.

**Analogy:** filter = a sieve. Rows that don't match fall through.

---

## 7. Adding conditional logic (`when`)

```python
df.withColumn("size",
    F.when(F.col("amount") > 1000, "large")
     .when(F.col("amount") > 100,  "medium")
     .otherwise("small"))
```
**Analogy:** an Excel `IF` formula, but with unlimited `ELSE IF`.
The first matching `when` wins — order matters.

---

## 8. Summarising (`groupBy` + `agg`)

```python
df.groupBy("country").agg(
    F.count("*").alias("orders"),
    F.sum("amount").alias("revenue"),
    F.avg("amount").alias("avg_order"),
)
```
- `groupBy` = "sort rows into buckets by this column".
- `agg` = "then calculate something per bucket".
- `.alias()` = "name the result column".
- Common aggs: `count`, `sum`, `avg`, `min`, `max`, `countDistinct`, `collect_list`.

**Analogy:** sorting a pile of receipts into country envelopes, then writing the total
on each envelope.

---

## 9. Joining two tables

```python
orders.join(customers, on="customer_id", how="left")
```
| `how` | Plain meaning |
|---|---|
| `inner` | keep only matching rows (both sides) |
| `left` | keep all left rows, fill blanks if no match |
| `semi` | keep left rows that **have** a match (left columns only) |
| `anti` | keep left rows that have **no** match |

**Analogy:** `left` = everyone on the guest list stays, even if they didn't RSVP.

---

## 10. Sorting and limiting

```python
df.orderBy(F.desc("amount"))
df.orderBy(F.col("amount").desc(), F.col("date").asc())
df.limit(10)
```

---

## 11. Writing data

```python
df.write.mode("overwrite").parquet("out/")
df.write.mode("append").format("delta").saveAsTable("gold.sales")
df.write.partitionBy("year").parquet("out/")
```
| `mode` | Plain meaning |
|---|---|
| `overwrite` | delete existing, write fresh |
| `append` | add to existing |
| `ignore` | do nothing if it exists |
| `error` (default) | fail if it exists |

---

## 12. The 5 mistakes beginners make

1. Forgetting `from pyspark.sql import functions as F`.
2. Using `and`/`or` instead of `&`/`|` — and forgetting the parentheses.
3. `df.filter(...)` without assigning it: `df = df.filter(...)` or `df2 = ...`.
4. Forgetting `.alias()` after an aggregation.
5. Expecting `select`/`filter` to print something — they're lazy. Add `show()`.
