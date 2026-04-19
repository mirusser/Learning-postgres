MVCC in PostgreSQL means **Multi-Version Concurrency Control**.

The core idea:
- PostgreSQL does not usually overwrite a row in place.
- It keeps **multiple row versions**.
- Each transaction sees the version that is valid for its snapshot.
- That lets readers and writers proceed with much less blocking.

## The mental model
Think of a row not as one thing, but as a **chain of versions over time**.

Suppose the row is:
```
id=1, balance=100
```

Transaction T1 updates it to 150.

PostgreSQL conceptually does this:
- old version: `balance=100`
- new version: `balance=150`

The old version is marked as no longer current, but it may still be visible to transactions that started earlier.

So at the same moment:
- an older transaction may still see `100`
- a newer transaction may see `150`

That is the *“multi-version”* part.

## Why PostgreSQL does this
Without MVCC, databases often have to make readers wait for writers, or writers wait for readers.

With MVCC:
- plain `SELECT` usually does not block plain `UPDATE`
- plain `UPDATE` usually does not block plain `SELECT`

That is one of PostgreSQL’s biggest strengths.

## How snapshots work
When a transaction starts, PostgreSQL gives it a **snapshot** of what transactions are considered visible.

That snapshot answers questions like:
- Which transactions were already committed when I started?
- Which were still in progress?
- Which row versions should I ignore?

So each transaction gets a consistent view of the database.

Under `READ COMMITTED` the snapshot is usually refreshed per statement.  
Under `REPEATABLE READ` it is kept for the whole transaction.

## What MVCC solves well
MVCC is great for:
- high read concurrency
- reducing read/write blocking
- giving transactions a consistent snapshot
- supporting isolation levels cleanly

That is why PostgreSQL handles mixed workloads well.

## What MVCC does not automatically solve
MVCC does **not** mean all concurrency bugs disappear.

Example:
1. T1 reads row A
2. T2 reads row A
3. T1 writes a new value
4. T2 writes a new value based on stale data

That can still cause a **lost update** unless you use one of:
- optimistic concurrency check
- `SELECT ... FOR UPDATE`
- a stronger isolation level
- an atomic SQL update

So MVCC helps with visibility and reduced blocking, but business correctness still needs proper write logic.

---
## Why UPDATE is really “delete + insert”

In PostgreSQL internals, `UPDATE` behaves a lot like:
- mark old tuple version dead/superseded
- insert a new tuple version

That is why `ctid` usually changes on update, and why `xmin` changes too.
## How this relates to optimistic concurrency

[[Optimistic concurrency]] says:
> “I will update only if the row is still the same version I read earlier.”

MVCC is what makes “same version” meaningful.

If you read a row with:
```sql
SELECT xmin, id, name  
FROM users  
WHERE id = 1;
```

and later do:
```sql
UPDATE users  
SET name = 'Alice 2'  
WHERE id = 1  
  AND xmin = $old_xmin;
```

then you are effectively saying:
- “Update only if the currently visible row version is still the one I originally saw.”

If another transaction already updated the row, the current visible version has a different `xmin`, so your update affects 0 rows.

So:
- **MVCC** creates row versions
- **optimistic concurrency** checks whether the version changed

MVCC is the mechanism; [[Optimistic concurrency]] is an application pattern built on top of it.

---
## Vacuum and dead tuples
Because PostgreSQL keeps old row versions, it needs cleanup.

When old row versions are no longer visible to any transaction, they become garbage and `VACUUM` can reclaim them.

So MVCC naturally creates:
- live tuples
- dead tuples
- cleanup work

That is why autovacuum is important in PostgreSQL.
## The cleanest intuition

A way to remember MVCC:
> PostgreSQL lets transactions read from a time-consistent picture of the database by storing row versions instead of overwriting rows immediately.

A way to remember optimistic concurrency is:
> “When I save, verify that the row version I originally saw is still the current one.”

## One compact example
Initial row:
```
(id=1, qty=5, xmin=100, xmax=null)
```

T200 starts and reads qty = 5.

T201 updates qty to 6.

Now internally:
```
old: (id=1, qty=5, xmin=100, xmax=201)  
new: (id=1, qty=6, xmin=201, xmax=null)
```

If T200 tries:
```sql
UPDATE items  
SET qty = 7  
WHERE id = 1 AND xmin = 100;
```

it gets 0 rows updated, because the current row version is no longer the one created by `xmin=100`.

That is MVCC plus optimistic concurrency working together.

## Bottom line
- MVCC = PostgreSQL keeps multiple row versions
- snapshots decide which version each transaction sees
- `xmin` and `xmax` drive row visibility
- `UPDATE` creates a new row version rather than overwriting the old one
- optimistic concurrency uses that idea to detect stale writes