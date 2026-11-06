# Row-Oriented Heap (PostgreSQL Internal Mechanism)

In database internals, **"Heap" does not refer to the RAM heap** (such as dynamic memory allocation via `malloc` or heap vs. stack). Instead, it describes an **unordered collection of data records on disk**.

## 1. Why It Is Called a "Heap"

- Unlike storage engines that physically sort table rows on disk using a clustered primary key index (e.g., MySQL InnoDB's clustered B-Tree), PostgreSQL writes rows into any available space in the table's disk file where they fit.
- Because rows are placed without inherent sequential order, the physical storage file is referred to as a **Heap File** (stored on disk in `$PGDATA/base/...` in 1 GB file segments).

## 2. Anatomy of an 8 KB Page / Block

PostgreSQL divides heap files into fixed **8 KB (8,192 bytes)** blocks called **Pages**. Every row (tuple) in that page contains all of its column values packed together sequentially:

```text
+-----------------------------------------------------------------------+
| Page Header (24 bytes: LSN, checksum, pointers to free space)         |
+-----------------------------------------------------------------------+
| Line Pointers / ItemIds (4 bytes each: ptr -> Tuple 1, Tuple 2...)   |
| [Item 1] [Item 2] [Item 3] ...                                        |
+-----------------------------------------------------------------------+
|                         <--- FREE SPACE --->                          |
+-----------------------------------------------------------------------+
| ... [Tuple 3: id, name, email, bio, created_at, ...]                  |
| ... [Tuple 2: id, name, email, bio, created_at, ...]                  |
| ... [Tuple 1: id, name, email, bio, created_at, ...]                  |
+-----------------------------------------------------------------------+
```

- **Tuples (Rows)** grow from the bottom of the page upward, while **Line Pointers** grow from the top downward.
- **Physical Row Identifier (`ctid`)**: Stored as a pair `(page_number, item_offset)`. When a secondary B-Tree index matches a query, it retrieves this `ctid` pointer and tells Postgres: _"Fetch page #42 from disk, then read line pointer #3"_.

## 3. How Memory Fits In (`shared_buffers`)

PostgreSQL cannot operate on raw disk blocks directly with CPU instructions:

1. **Disk to Memory**: When a query needs data, the database engine loads the **entire 8 KB page** containing the matching row from disk into PostgreSQL's in-memory buffer pool called **`shared_buffers`**.
2. **Execution in RAM**: The query executor processes and extracts tuple columns while the page resides in memory.
3. **Dirty Pages**: When rows are inserted or updated, the page is modified in `shared_buffers` (marked "dirty") and subsequently flushed back to disk by background writer or checkpointer processes.

## 4. The Architectural Contrast with BigQuery

Consider a table with 10,000,000 users and 50 columns (including heavy text columns like `bio`, `address`, `json_metadata`):

```sql
SELECT AVG(age) FROM users;
```

- **In PostgreSQL (Row-Oriented)**:
  - Even though the query only needs the 4-byte integer `age`, Postgres must read **every single 8 KB heap page** of the entire table from disk into `shared_buffers`.
  - Because all 50 columns are stored together inside each tuple, gigabytes of unrequested strings, text, and JSON data are pulled across the storage bus and into memory cache just to compute the average age.
- **In BigQuery (Columnar - Capacitor)**:
  - There are no heap pages. Every column is stored in its own independent set of compressed file blocks on Google Colossus.
  - BigQuery **only reads the `age` column blocks**. The other 49 columns are completely skipped at the disk, network, and memory levels—resulting in minimal I/O and near-zero query cost.
