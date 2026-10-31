# Setup — Databricks Free Edition (replaces Community Edition)

> The old "Community Edition" was retired in 2025. Use **Free Edition**.
> Docs: https://docs.databricks.com/aws/en/getting-started/free-edition

## 1. Sign up (~5 min)
1. Go to **https://login.databricks.com/?intent=CE_SIGN_UP**
   (or https://www.databricks.com/learn/free-edition → "Sign up for Free Edition")
2. Choose **Continue with email** / Google / Microsoft.
3. Enter the 6-digit code sent to your email.
4. Fill in name + a company/university field (anything is fine for learning).
5. Your workspace is created automatically — **serverless compute is included**, no cluster setup needed.

## 2. Create your notebook
1. Left sidebar → **Workspace** → **Create** → **Notebook**
2. Name: `lesson-01`
3. Default language: **Python**
4. Connect it to **Serverless** compute (should be the default).

**Faster path:** import the file I made instead.
`Workspace → ⋮ → Import → File → exercises/lesson_01_databricks.py`

## 3. Key differences from a local install
| Local PySpark | Databricks |
|---|---|
| You create `SparkSession.builder.master("local[*]")` | `spark` **already exists** — do not create it |
| Global temp files on disk | Use `dbfs:/` or Unity Catalog volumes |
| `df.show()` | `display(df)` — nicer interactive table |
| You manage versions | Spark version is fixed by the platform |
| Full control of partitions/shuffles | Some limits on serverless |

## 4. Free Edition limits that matter for this course
- Serverless only — no custom clusters, no `local[*]`
- Quota-limited compute (it will pause if you hammer it)
- Some cluster-level Spark configs are off-limits
- **Weeks 4–5 (performance tuning, streaming) will be partly theoretical here.**

👉 Plan: learn Weeks 1–3 on Databricks (real-world feel), then add
**local PySpark via Docker** for the performance deep-dive. I'll set that up when we get there.

## 5. Verify it works
Paste into a cell and run (`Shift+Enter`):
```python
print(spark.version)
spark.range(5).show()
```
If you see a version number and a 5-row table, you're live. 🎉
