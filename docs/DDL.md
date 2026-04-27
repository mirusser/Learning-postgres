**DDL** means **Data Definition Language**.

In PostgreSQL, DDL is the part of SQL used to **define and change database structure**, not the data itself.

> DDL in PostgreSQL is the subset of SQL used to create, modify, and remove [[schema objects]].

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

One PostgreSQL-specific detail worth knowing: many DDL commands are **transactional**, (so you can often run them inside BEGIN ... ROLLBACK / COMMIT), but not all. 

For example, CREATE DATABASE and DROP DATABASE cannot run inside a transaction block. SQL Server is similar: many DDL commands are transactional, but there are important exceptions.

---

SQL Server / MS SQL comparison:

In Microsoft SQL Server, DDL means the same general thing:
SQL used to create, alter, and remove database structure.

Typical DDL commands are also:

CREATE
ALTER
DROP
TRUNCATE

SQL Server uses the T-SQL dialect, so syntax and data types differ.

Example:

```sql
CREATE TABLE dbo.users (
    id bigint NOT NULL CONSTRAINT PK_users PRIMARY KEY,
    email nvarchar(320) NOT NULL,
    created_at datetime2 NOT NULL
);
```

```sql
ALTER TABLE dbo.users
ADD is_active bit NOT NULL DEFAULT 1;
```

```sql
DROP TABLE dbo.users;
```

Important differences from PostgreSQL:

- SQL Server commonly uses dbo as the default schema.
- Use nvarchar(max) / varchar(max), not text.
- SQL Server timestamp is not a date/time type; it means rowversion.
- Use datetime2 or datetimeoffset for date/time columns.
- Renaming is often done with sp_rename.
- Identity columns use IDENTITY(1,1).

Transactional DDL:

Many SQL Server DDL operations are transactional and can be rolled back inside:

```sql
BEGIN TRAN;
CREATE TABLE dbo.test_table (id int);
ROLLBACK;
```

But not all DDL is allowed in transactions.
For example, CREATE DATABASE must run in autocommit mode.

Also, DDL can take strong schema locks, so migrations can block or be blocked by active queries.