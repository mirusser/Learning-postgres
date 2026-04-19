Optimistic concurrency is a way to prevent **lost updates** without locking a row for the whole time a user is editing it.

The idea is:
1. Read the row.
2. Remember some version of what you read.
3. When updating, only succeed if the row is still at that same version.
4. If someone else changed it first, your update affects 0 rows, and you handle that as a conflict.

In PostgreSQL, this is usually done with a **version column** or **updated_at** timestamp.

Why it is called “optimistic”:
- You assume conflicts are rare.
- You do **not** hold locks while the user or app is thinking.
- You only check for conflict at write time.


PostgreSQL already uses **[[MVCC]]** internally, so readers do not block writers and writers do not block readers in the usual way. But MVCC alone does **not** solve lost updates in application workflows where:
- transaction A reads a row
- transaction B reads the same row
- A updates it
- B updates it later based on stale data

Optimistic concurrency adds the missing application-level check

---

Example with a version column:
```sql
CREATE TABLE accounts (  
  id bigint primary key,  
  balance numeric not null,  
  version integer not null default 1  
);
```

Read the row:
```sql
SELECT id, balance, version  
FROM accounts  
WHERE id = 42;
```

Suppose you got `version = 7`. Then update like this:
```sql
UPDATE accounts  
SET balance = 150,  
    version = version + 1  
WHERE id = 42  
  AND version = 7;
```


What happens:
- If nobody changed the row since you read it, 1 row is updated.
- If another transaction already changed it and bumped the version, 0 rows are updated.

That `0 rows updated` result is the optimistic concurrency conflict.

---

A practical rule:
- For full-row edits from apps or UIs, use a `version` column.
- For counters and arithmetic changes, prefer a single atomic `UPDATE`.
- For strong coordination, use locks or higher isolation when needed.