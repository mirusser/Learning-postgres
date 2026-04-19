**DDL** means **Data Definition Language**.

In PostgreSQL, DDL is the part of SQL used to **define and change database structure**, not the data itself.

> DDL in PostgreSQL is the subset of SQL used to create, modify, and remove schema objects.

Typical DDL operations are:
- `CREATE` — create database objects
- `ALTER` — modify them
- `DROP` — remove them
- `TRUNCATE` — quickly remove all rows from a table
- sometimes `COMMENT` and `RENAME` are grouped with schema-definition work too

Examples:
```sql
CREATE TABLE users (  
    id bigint primary key,  
    email text not null  
);

ALTER TABLE users  
ADD COLUMN created_at timestamp;

DROP TABLE users;
```

So DDL is about things like:
- tables
- indexes
- schemas
- views
- sequences
- constraints

Useful contrast:
- **DDL** → structure/schema
- **DML** → data changes like `INSERT`, `UPDATE`, `DELETE`
- **DQL** → querying, usually `SELECT`

---

One PostgreSQL-specific detail worth knowing: many DDL commands are **transactional**, so you can often run them inside `BEGIN ... ROLLBACK` / `COMMIT`, which is very handy for migrations.