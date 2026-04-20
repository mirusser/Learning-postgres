`TRUNCATE TABLE <table_name>;`  removes **all rows from a table very quickly** by handling the table as a storage object, rather than deleting rows one by one.

In PostgreSQL, `TRUNCATE TABLE x;` means:

> “Atomically replace table `x` with an empty version, using a strong lock, without deleting rows one by one.”

## What it does
At the SQL level:
```sql
TRUNCATE TABLE my_table;
```
This empties `my_table`

Unlike:
```sql
DELETE FROM my_table;
```
with no `WHERE` clause, `TRUNCATE` is designed for the special case “remove everything.”

## Why it is fast
`DELETE` removes rows individually. That means PostgreSQL typically must:
- visit each row
- mark each row as deleted
- update indexes for those row details
- generate row-level effects such as `ON DELETE` triggers
- leave dead tuples behind that VACUUM later cleans up

`TRUNCATE` does not do row-by-row work. It effectively replaces or resets the table’s physical storage so PostgreSQL no longer sees any rows in it.

Conceptually:
- `DELETE`: cross out every line in a notebook
- `TRUNCATE`: throw away the notebook and start with a fresh empty one

That is why `TRUNCATE` is usually much faster for large tables.

## It is [[DDL]]-like, but transactional
`TRUNCATE` behaves more like a structure-changing command than a row-manipulation command, even though its result is about data.

Important PostgreSQL behavior:
- it is **transactional**
- it can be **rolled back** if executed inside a transaction block

Example:
```sql
BEGIN;  
  
TRUNCATE TABLE my_table;  
  
-- table appears empty here  
  
ROLLBACK;
```

After the rollback, the data is back.

## Locking behavior
`TRUNCATE` takes a very strong lock: **ACCESS EXCLUSIVE** on the target table.

That means while the truncate is in progress, other sessions generally cannot:
- read from the table
- write to the table
- modify the table

This is stronger than many `DELETE` operations.

Why? Because PostgreSQL is not removing rows gradually. It is making a table-wide storage-level change, so it needs full control.

This matters in production. Even though `TRUNCATE` is fast, it can block or be blocked by other transactions.

Example scenario:
- Session A is running a long `SELECT` on `my_table`
- Session B runs `TRUNCATE TABLE my_table;`

Session B may wait until Session A releases conflicting locks. Or the reverse can happen if B gets the exclusive lock first.

## What happens to indexes
Indexes are effectively emptied too.

Because the table storage is reset, PostgreSQL does not need to delete index entries one by one. The indexes end up empty along with the table.

This is another reason it is much faster than `DELETE`.

## MVCC implications
PostgreSQL uses [[MVCC]], so with normal `DELETE`, old row versions may remain visible to older transactions until cleanup.

`TRUNCATE` is special. It is **not MVCC-safe in the same way as row-by-row operations**.

Practical consequence:
- transactions that started before the truncate may see the table as empty in ways that differ from normal row-version visibility expectations

The key idea is that `TRUNCATE` swaps out the relation storage instead of creating deleted row versions for each row.

So although PostgreSQL preserves transaction atomicity, `TRUNCATE` is not just “a faster delete.” It has different concurrency semantics.

## Triggers: which fire and which do not
`TRUNCATE` does **not** fire `ON DELETE` row-level triggers, because no rows are deleted one by one.

Instead, PostgreSQL supports **`ON TRUNCATE` triggers**.

So:
- `BEFORE DELETE` trigger: **not fired**
- `AFTER DELETE` trigger: **not fired**
- `BEFORE TRUNCATE` trigger: **fired**
- `AFTER TRUNCATE` trigger: **fired**

Example:
```sql
CREATE TRIGGER log_truncate  
AFTER TRUNCATE ON my_table  
FOR EACH STATEMENT  
EXECUTE FUNCTION some_function();
```

If your application relies on delete triggers for audit or cascading logic, switching from `DELETE` to `TRUNCATE` can silently change behavior.

## Foreign key behavior

If another table references your table through a foreign key, PostgreSQL usually refuses to truncate it unless you explicitly handle the dependency.

Example:
- `orders(customer_id)` references `customers(id)`

Then:
```sql
TRUNCATE TABLE customers;
```

may fail, because rows in `orders` would now reference nonexistent customers.

You have two main options.

### 1. Truncate dependent tables too
```sql
TRUNCATE TABLE customers, orders;
```
This works if all relevant tables are included.
### 2. Use CASCADE
```sql
TRUNCATE TABLE customers CASCADE;
```
This tells PostgreSQL to also truncate tables that have foreign-key dependencies requiring it.

Be careful: `CASCADE` can affect more tables than you expect.

## RESTRICT vs CASCADE
By default, `TRUNCATE` behaves like `RESTRICT`.

Equivalent idea:
```sql
TRUNCATE TABLE customers RESTRICT;
```
This means:
- do not truncate if dependent foreign-key relationships would make it unsafe

Using:
```sql
TRUNCATE TABLE customers CASCADE;
```
This means:
- include dependent tables automatically

## Identity and sequence behavior
By default, truncating a table does **not necessarily reset associated sequences**.

PostgreSQL supports two options:
### 1. CONTINUE IDENTITY
Keep sequences as they are.
```sql
TRUNCATE TABLE my_table CONTINUE IDENTITY;
```

This is the default behavior.

If the last inserted id was 500 before truncation, the next insert may still use 501.

### 2. RESTART IDENTITY
Reset sequences associated with the truncated table.
```sql
TRUNCATE TABLE my_table RESTART IDENTITY;
```

Then inserts start again from the sequence’s start value, often 1.
### Important subtlety
`RESTART IDENTITY` affects sequences **owned by columns of the truncated tables**. It does not reset arbitrary sequences unless they are linked as owned sequences.

For a `SERIAL` or `GENERATED ... AS IDENTITY` column, this usually works as expected.

## WAL and logging
`TRUNCATE` is logged in PostgreSQL’s write-ahead log, but not as millions of row deletions.

Instead, PostgreSQL logs the storage-level relation changes needed for crash recovery and replication.

Effects:
- much less WAL than deleting huge numbers of rows
- still safe for crash recovery
- still replicated appropriately to physical replicas

So it is efficient, but not “unlogged” or unsafe.

## Disk space effects
A big reason people use `TRUNCATE` is immediate space reclamation for the table.

With `DELETE`:
- rows become dead
- disk space may not be returned immediately
- VACUUM is needed to reclaim internal reuse, and even then file shrinking is different

With `TRUNCATE`:
- PostgreSQL replaces the table storage with a new empty one
- old storage can be dropped immediately at commit

That means the table becomes physically small again much faster than with `DELETE`.

## Permissions required
You cannot truncate a table just because you can delete from it.

`TRUNCATE` requires the **TRUNCATE privilege** on the table, or ownership/superuser-level authority.

So a user with `DELETE` permission may still get an error on `TRUNCATE`.

## Multiple tables
You can truncate more than one table in one statement:
```sql
TRUNCATE TABLE table_a, table_b, table_c;
```

This is often better than separate statements because PostgreSQL can handle dependencies and locking in one coordinated operation.

## Partitioned tables
For partitioned tables, `TRUNCATE` has important behavior.

If you truncate the parent partitioned table:
```sql
TRUNCATE TABLE parent_table;
```

PostgreSQL truncates all partitions.

This is usually what you want, but it is worth remembering because the parent may hold no rows itself while the partitions do.

You can also truncate individual partitions directly.

## Inheritance behavior
If the table uses older-style table inheritance, `TRUNCATE` can include descendants unless `ONLY` is used.

Example:
```sql
TRUNCATE TABLE parent_table;
```
may affect inheriting child tables.

To limit it:
```sql
TRUNCATE TABLE ONLY parent_table;
```
That distinction matters in inheritance setups.

## Difference from DELETE in detail
Here is the practical comparison.

### DELETE FROM my_table;
- row by row
- can use `WHERE`
- fires delete triggers
- respects row-level MVCC behavior
- leaves dead tuples
- may require VACUUM
- slower on large tables
- can be less disruptive in some concurrency cases

### TRUNCATE TABLE my_table;
- all rows only, no `WHERE`
- no row-by-row delete
- fires truncate triggers, not delete triggers
- stronger lock
- minimal per-row overhead
- resets storage efficiently
- much faster for full-table clearing

## You cannot add WHERE
This is a common misconception.

This is valid:
```sql
DELETE FROM my_table WHERE created_at < now() - interval '30 days';
```

This is not:
```sql
TRUNCATE TABLE my_table WHERE ...;
```

`TRUNCATE` is all-or-nothing for the targeted table(s).

## Rollback example with identity reset
```sql
BEGIN;  
  
TRUNCATE TABLE my_table RESTART IDENTITY;  
  
INSERT INTO my_table DEFAULT VALUES;  
  
ROLLBACK;
```

After the rollback:
- the original rows are back
- the sequence restart is rolled back too

That transactional consistency is a very useful PostgreSQL feature.

## Common examples

### Basic truncate
```sql
TRUNCATE TABLE logs;
```

Empties `logs`, keeps identity/sequence progression unchanged.

### Truncate and reset ids
```sql
TRUNCATE TABLE logs RESTART IDENTITY;
```

Empties `logs` and resets owned sequences.

### Truncate with dependent tables
```sql
TRUNCATE TABLE customers CASCADE;
```

Empties `customers` and other referencing tables that must be truncated too.

### Truncate several tables together
```sql
TRUNCATE TABLE orders, order_items RESTART IDENTITY;
```

Clears both tables and resets their owned sequences.

## Under the hood, roughly
Internally, PostgreSQL does not iterate over tuples. It performs relation-level operations that amount to replacing the table’s storage with a new empty relation file.

The old storage is kept transactionally safe until commit semantics determine whether it is dropped or preserved.

That is why `TRUNCATE` can be:
- fast
- rollbackable
- space-efficient
- different from normal MVCC row operations

## When to use it
Use `TRUNCATE` when:
- you want to remove all rows
- speed matters
- you do not need row-level delete trigger behavior
- you can tolerate the stronger lock
- you understand the foreign-key implications

Typical use cases:
- clearing staging tables
- resetting test fixtures
- emptying transient ETL tables
- purging temporary bulk-load tables

## When not to use it
Avoid `TRUNCATE` when:
- you need to remove only some rows
- you rely on `ON DELETE` trigger logic
- you want gentler concurrency behavior
- you are not fully sure what `CASCADE` will affect

## Biggest gotchas
The main mistakes people make are:
- assuming it is just a faster `DELETE`
- forgetting it takes `ACCESS EXCLUSIVE`
- forgetting `ON DELETE` triggers do not fire
- using `CASCADE` without realizing how many tables it may empty
- expecting identity reset without `RESTART IDENTITY`

## One-line mental model
In PostgreSQL, `TRUNCATE TABLE x;` means:

> “Atomically replace table `x` with an empty version, using a strong lock, without deleting rows one by one.”