# Glossary — plain English only

Every term used in this course, defined as if you've never seen Spark.
Updated as we learn. If a term is missing, ask and it gets added.

---

## The basics

| Term | Plain meaning | Analogy |
|---|---|---|
| **Spark** | A program that processes data too big for one computer by splitting the work across several computers. | A catering company instead of one home cook. |
| **Data** | Information arranged in rows and columns — like a spreadsheet. | A stack of order slips. |
| **Row** | One record. One order, one customer, one click. | One line in a spreadsheet. |
| **Column** | One field across all rows. | One column in a spreadsheet. |
| **DataFrame** | Spark's name for a table (rows + columns) that can be processed in parallel. | A spreadsheet you can hand to many workers at once. |
| **Schema** | The list of columns and their types (text, number, date). | The labels on a filing cabinet telling you what's inside. |

## The machines

| Term | Plain meaning | Analogy |
|---|---|---|
| **Cluster** | A group of computers working together as one. | A restaurant with several kitchens. |
| **Node** | One computer inside a cluster. | One kitchen. |
| **Driver** | The program that runs *your* code. It decides what work to do and hands it out. It does **not** process the data. | Head chef: writes the plan and shouts orders. |
| **Executor** | A process on a worker machine that actually processes data and holds it in memory. | Line cook: does the actual cooking. |
| **Core** | One processor inside a machine. One core does one task at a time. | One stove. |
| **Cluster manager** | Software that hands out machines to Spark (YARN, Kubernetes, Standalone). | The landlord who assigns kitchens. |
| **Local mode (`local[*]`)** | Driver and executors all inside one program on your laptop. | A one-person kitchen doing every job. |
| **Serverless** | The platform starts and stops the machines for you; you never see them. | A takeaway service with invisible kitchens. |
| **Databricks** | A company that sells a managed Spark platform with extra tools. | A restaurant franchise: same cooking, nicer building. |

## The work

| Term | Plain meaning | Analogy |
|---|---|---|
| **Job** | All the work triggered by **one action**. | One order from a customer. |
| **Stage** | A chunk of a job where no data has to be moved between machines. A job is cut into stages wherever a shuffle happens. | A cooking phase; after it, ingredients must be carried to another counter. |
| **Task** | The work of processing **one partition**. One task per partition. | One dish. |
| **Partition** | One chunk of the data. Data is always split into partitions. | One portion of ingredients. |
| **Transformation** | An instruction that describes a change (`select`, `filter`, `groupBy`). It does **nothing** on its own. | Writing a step in the recipe, not cooking it. |
| **Action** | An instruction that asks for a result (`show`, `count`, `write`). This is what starts the work. | Actually cooking and plating. |
| **Lazy evaluation** | Spark waits until an action before doing anything. Transformations only build a plan. | The chef reads the whole order before switching on the stove. |
| **Shuffle** | Moving data between machines so related rows end up together. Expensive. | Carrying ingredients from one kitchen to another. |
| **DAG** | The graph of steps Spark will perform, drawn from your transformations. | The recipe flowchart. |
| **Narrow dependency** | Each output partition needs only one input partition. No data movement. | One cook takes one tray and works on it. |
| **Wide dependency** | Output partitions need data from many input partitions → requires a shuffle. | Every cook needs something from every other tray. |
| **Stage boundary** | The point where a shuffle happens and a new stage begins. | The moment ingredients must be carried across the kitchen. |

## Performance words

| Term | Plain meaning | Analogy |
|---|---|---|
| **Catalyst** | Spark's built-in planner that rewrites your query to run faster before executing it. | An experienced chef who rearranges your recipe to save time. |
| **Physical plan** | The concrete "how I will actually do it" that Spark prints with `explain()`. | The final kitchen work order. |
| **Predicate pushdown** | Reading only the rows that match your filter, instead of reading everything then filtering. | Skipping boxes whose label says "no 2024 data". |
| **Column pruning** | Reading only the columns you asked for. | Only opening the drawers you need. |
| **AQE (Adaptive Query Execution)** | Spark re-deciding some choices *while* the job runs, based on real data sizes. | The chef adjusting mid-service after seeing the actual portions. |
| **Photon** | Databricks' faster engine written in C++. Not part of open-source Spark. | A turbocharged stove only available in that franchise. |
| **Partial aggregation** | Counting/summing within each partition *before* moving data, so less data travels. | Each cook counts their own tray first, then reports one number. |
| **cache / persist** | Keep a result in memory so later steps don't recompute it. | Photocopying a document instead of walking back to the cabinet. |
| **Spill** | Running out of memory, so Spark writes data to disk temporarily. | The worktop is full, so items go on the floor. |
| **Evict** | Dropping cached data from memory because space ran out; it must be recomputed later. | Throwing a folder off the desk to make room. |
| **Lineage** | Spark's memory of *how* a DataFrame was built, allowing it to rebuild lost pieces. | The recipe lets you remake a dropped dish. |
| **Broadcast join** | Copying a small table to every machine so no data has to be shuffled. | Photocopying a small price list for every cook. |
| **Skew** | One partition holding far more data than the others, so one worker does most of the work. | One cook gets 90% of the orders. |
