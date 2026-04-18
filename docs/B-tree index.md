**B-tree index** is the standard **balanced tree** index structure. 
PostgreSQL describes it as a _multi-way balanced tree_; values are stored in sorted order, internal pages guide navigation, and leaf pages contain index tuples that point to table rows. 

It works for data types that can be put into a well-defined linear order.

A good mental model is:
```
root  
 ├─ internal page  
 │   ├─ leaf page: [10] [12] [15]  
 │   └─ leaf page: [18] [21] [25]  
 └─ internal page  
     ├─ leaf page: [30] [31] [40]  
     └─ leaf page: [45] [50] [60]

```

The point is not “tree” by itself, but **sorted tree**. 
Because entries are ordered, PostgreSQL can jump to the relevant part of the index and then scan forward through the matching range, which is why B-trees are good for `=`, `<`, `<=`, `>=`, `>`, and related predicates like `BETWEEN` and `IN`. B-tree is also the only PostgreSQL index type that can directly produce sorted output for `ORDER BY`.

## What a B-tree index is good for

Typical examples:
```SQL
CREATE INDEX idx_users_email ON users (email);  
CREATE INDEX idx_orders_created_at ON orders (created_at);
```

These are good when you query like:
```SQL
SELECT * FROM users WHERE email = 'a@example.com';  
  
SELECT * FROM orders  
WHERE created_at >= '2026-01-01'  
  AND created_at <  '2026-02-01';  
  
SELECT * FROM orders  
ORDER BY created_at DESC  
LIMIT 20;
```

That last case matters: PostgreSQL can often satisfy `ORDER BY ... LIMIT` directly from a B-tree, avoiding a separate sort.

## What “concatenated B-tree index” means

In PostgreSQL’s own docs, the official term is **multicolumn B-tree index**. What many people call a **concatenated index** is just a B-tree index with multiple key columns, for example:

```SQL
CREATE INDEX idx_orders_customer_created  
ON orders (customer_id, created_at);
```

PostgreSQL says an index can be defined on more than one column, and for B-tree indexes these are **multiple key columns**.

The word **concatenated** can be misleading, because PostgreSQL is **not** literally concatenating the columns into one string value.  
Instead, it stores and orders the index by the key columns **lexicographically**:

```
(customer_id, created_at)  
  
(1, 2026-01-01)  
(1, 2026-01-03)  
(1, 2026-01-10)  
(2, 2026-01-02)  
(2, 2026-01-05)  
(3, 2026-01-01)

```

So the first column is the primary sort key, the second breaks ties within the first, the third breaks ties within the first two, and so on. That ordering behavior is exactly why PostgreSQL emphasizes the **leading (leftmost) columns** rule for multicolumn B-trees.

## The most important rule: leftmost columns

For a multi-column B-tree index, PostgreSQL says it is most efficient when there are constraints on the **leading (leftmost) columns**. The exact rule is:
- equality constraints on leading columns
- plus any inequality constraint on the first column without an equality constraint

are what limit how much of the index must be scanned. Columns further to the right can still be checked in the index, but they do not necessarily reduce the scanned portion.

Using:
```SQL
CREATE INDEX idx_orders_customer_created  
ON orders (customer_id, created_at);
```

### Very good fits
```SQL
WHERE customer_id = 42

WHERE customer_id = 42  
  AND created_at >= '2026-01-01'

ORDER BY customer_id, created_at
```

### Often not a good fit
```SQL
WHERE created_at >= '2026-01-01'
```

because the leftmost column `customer_id` is missing. PostgreSQL can sometimes use **skip scan** for this kind of case, but only when that is expected to be profitable. Otherwise it may prefer a sequential scan.

## Why column order matters so much

These two indexes are not equivalent:
```SQL
CREATE INDEX idx_a ON orders (customer_id, created_at);  
CREATE INDEX idx_b ON orders (created_at, customer_id);
```

They support different access patterns because the physical ordering is different. If your common query is:
```SQL
WHERE customer_id = 42  
  AND created_at >= '2026-01-01'  
ORDER BY created_at
```

then `(customer_id, created_at)` is usually the natural order, because rows for one customer are grouped together first, then ordered by date inside that group.

A clean interview sentence is:
> “A multicolumn B-tree index is ordered first by column 1, then by column 2 within column 1, then by column 3 within the first two, so column order determines which predicates can narrow the scan efficiently.”

--- 
## Single-column B-tree vs concatenated/multicolumn B-tree

### Single-column
```SQL
CREATE INDEX idx_orders_created_at ON orders (created_at);
```

Best when the main filter/order pattern is on one column.

### Multicolumn / “concatenated”
```SQL
CREATE INDEX idx_orders_customer_created  
ON orders (customer_id, created_at);
```

Best when queries commonly use both columns in that order, especially with the leftmost one present. PostgreSQL also cautions that multicolumn indexes should be used sparingly, and indexes with more than three columns are often not helpful unless workload patterns are very stylized.

## Important nuance: key columns vs `INCLUDE` columns

This is a common interview trap.

```SQL
CREATE INDEX idx_orders_customer_created  
ON orders (customer_id, created_at)  
INCLUDE (status, total_amount);
```

Here:
- `customer_id, created_at` are the **key columns**
- `status, total_amount` are **included columns**

Only the key columns define the B-tree ordering and scan narrowing behavior. PostgreSQL explicitly says multiple key columns are independent from whether `INCLUDE` columns are added.

So `INCLUDE` does **not** make the index a 4-column concatenated key. It is still a 2-column B-tree key with extra payload columns.

## What skip scan means here

PostgreSQL’s multicolumn docs note that for a B-tree index it may apply **skip scan**. That means if you have an index like `(x, y)` and the query is only `WHERE y = 7700`, PostgreSQL may internally perform repeated searches over possible `x` values if it expects that to skip most of the index cheaply. But this is conditional and only useful when the missing leading column has relatively few distinct values.

So the modern, precise version of the “leftmost prefix rule” is:

- leftmost columns still matter most
- but PostgreSQL may sometimes salvage a non-leftmost predicate with skip scan

## Best concise interview answer

> “A B-tree index in PostgreSQL is the standard balanced, sorted index structure for values with a defined order. It is good for equality, range, and ordered retrieval. A ‘concatenated B-tree index’ is what PostgreSQL calls a multicolumn B-tree index: the key is ordered lexicographically, first by the first column, then the second, and so on. That’s why leftmost column order matters so much for which queries can narrow the scan efficiently.”

## Super short version
```
B-tree index  
= sorted tree for one ordered key  
  
Concatenated / multicolumn B-tree  
= sorted tree for (col1, col2, col3...)  
  ordered by col1 first, then col2, then col3
```