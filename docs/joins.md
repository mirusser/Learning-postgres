# Joins in PostgreSQL

## Summary
A join combines rows from two row sources.

Most joins combine rows based on a match condition such as:

```sql
customers.id = orders.customer_id
```

`CROSS JOIN` is the exception: it returns every possible combination and has no match condition.

## Join Overview

| Join type | Rows preserved | What happens to unmatched rows | Typical use |
| --- | --- | --- | --- |
| `INNER JOIN` | Only matching rows | Unmatched rows are removed | Return only rows that match on both sides |
| `LEFT JOIN` | All rows from the left side | Right-side columns become `NULL` | Keep all parent rows, even without children |
| `RIGHT JOIN` | All rows from the right side | Left-side columns become `NULL` | Same logic as `LEFT JOIN`, but written from the other side |
| `FULL JOIN` | All rows from both sides | Missing columns on either side become `NULL` | Find matches plus both kinds of non-matches |
| `CROSS JOIN` | Every combination | No matching step | Generate combinations deliberately |

## Base Example Tables

```text
customers
---------
id | name
1  | Alice
2  | Bob
3  | Carol
```

```text
orders
------
id | customer_id | total
10 | 1           | 50
11 | 1           | 80
12 | 2           | 30
```

Common join condition:

```sql
customers.id = orders.customer_id
```

For `RIGHT JOIN` and `FULL JOIN`, this document adds one unmatched order:

```text
id | customer_id | total
13 | 99          | 20
```

## Core Join Types

### `INNER JOIN`
An `INNER JOIN` returns only rows where the join condition matches on both sides.

```sql
SELECT c.name, o.id, o.total
FROM customers c
INNER JOIN orders o
  ON c.id = o.customer_id;
```

Result:

```text
Alice | 10 | 50
Alice | 11 | 80
Bob   | 12 | 30
```

Mental model: keep only the intersection.

Notes:
- `JOIN` by itself usually means `INNER JOIN`
- this is the most common join

### `LEFT JOIN` / `LEFT OUTER JOIN`
A `LEFT JOIN` returns:
- all rows from the left table
- matching rows from the right table
- `NULL` for right-side columns when no match exists

```sql
SELECT c.name, o.id, o.total
FROM customers c
LEFT JOIN orders o
  ON c.id = o.customer_id;
```

Result:

```text
Alice | 10   | 50
Alice | 11   | 80
Bob   | 12   | 30
Carol | NULL | NULL
```

Mental model: keep everything from the left, match what you can from the right.

Note: `LEFT JOIN` and `LEFT OUTER JOIN` mean the same thing. `OUTER` is optional.

### `RIGHT JOIN` / `RIGHT OUTER JOIN`
A `RIGHT JOIN` is the mirror image of a `LEFT JOIN`.

It returns:
- all rows from the right table
- matching rows from the left table
- `NULL` for left-side columns when no match exists

```sql
SELECT c.name, o.id, o.total
FROM customers c
RIGHT JOIN orders o
  ON c.id = o.customer_id;
```

Result:

```text
Alice | 10 | 50
Alice | 11 | 80
Bob   | 12 | 30
NULL  | 13 | 20
```

Mental model: keep everything from the right, match what you can from the left.

Practical note: many teams prefer rewriting a `RIGHT JOIN` as a `LEFT JOIN` by swapping table order.

### `FULL JOIN` / `FULL OUTER JOIN`
A `FULL JOIN` returns:
- all matching rows
- unmatched rows from the left table
- unmatched rows from the right table

Missing values are filled with `NULL`.

```sql
SELECT c.name, o.id, o.total
FROM customers c
FULL JOIN orders o
  ON c.id = o.customer_id;
```

Result:

```text
Alice | 10   | 50
Alice | 11   | 80
Bob   | 12   | 30
Carol | NULL | NULL
NULL  | 13   | 20
```

Mental model: keep everything from both sides.

### `CROSS JOIN`
A `CROSS JOIN` returns the Cartesian product.

That means:
- every row from the first source
- combined with every row from the second source

If one source has 3 rows and the other has 4 rows, the result has 12 rows.

Example:

```text
colors
------
red
blue
```

```text
sizes
-----
S
M
L
```

```sql
SELECT *
FROM colors
CROSS JOIN sizes;
```

Result:

```text
red  | S
red  | M
red  | L
blue | S
blue | M
blue | L
```

Mental model: all combinations.

Important:
- a normal `CROSS JOIN` has no `ON` clause
- `FROM a CROSS JOIN b` is equivalent to `FROM a INNER JOIN b ON TRUE`
- `FROM a, b` is also equivalent to a cross join, but only in simple cases

Watch out: when more than two tables appear, comma syntax and explicit `JOIN` do not always mean the same thing, because `JOIN` binds more tightly than comma syntax.

## Related Patterns and Syntax

### Self Join
A self join is not a separate SQL keyword. It is a pattern: a table joined to itself.

Useful for:
- parent-child relationships
- employee-manager relationships
- comparing rows within one table

```text
employees
---------
id | name | manager_id
1  | CEO  | NULL
2  | Ann  | 1
3  | Ben  | 1
4  | Cara | 2
```

```sql
SELECT e.name AS employee,
       m.name AS manager
FROM employees e
LEFT JOIN employees m
  ON e.manager_id = m.id;
```

Result:

```text
CEO  | NULL
Ann  | CEO
Ben  | CEO
Cara | Ann
```

Aliases are essential in self joins.

### `JOIN ... USING`
`USING` is not a different join type. It is join syntax.

Use it when both sides have the same join-column name.

```sql
SELECT *
FROM table_a
JOIN table_b
USING (id);
```

This is shorthand for:

```sql
ON table_a.id = table_b.id
```

Special behavior: the joined column appears only once in the output.

Example:

```text
table_a
-------
id | val_a
```

```text
table_b
-------
id | val_b
```

Output columns:

```text
id | val_a | val_b
```

`USING` is a good fit when the common key has the same name on both sides.

### `NATURAL JOIN`
A `NATURAL JOIN` automatically joins on every column name shared by both inputs.

```sql
SELECT *
FROM a
NATURAL JOIN b;
```

If both tables have columns named `id` and `code`, PostgreSQL joins on both columns.

Why this is risky:
- the join condition is implicit
- schema changes can silently change query behavior
- it is easy to join on more columns than intended

PostgreSQL-specific caveat: if the two inputs share no column names, `NATURAL JOIN` behaves like `CROSS JOIN`.

It can combine with join families:
- `NATURAL JOIN`
- `NATURAL LEFT JOIN`
- `NATURAL RIGHT JOIN`
- `NATURAL FULL JOIN`

Most production SQL prefers explicit `ON` or `USING` clauses.

### `LATERAL`
`LATERAL` lets a subquery on the right side refer to columns from row sources on the left side.

Example: get the latest order per customer.

```sql
SELECT c.name, o.id, o.total
FROM customers c
LEFT JOIN LATERAL (
    SELECT id, total
    FROM orders o
    WHERE o.customer_id = c.id
    ORDER BY id DESC
    LIMIT 1
) o ON TRUE;
```

The subquery can use `c.id`, which comes from the left side.

Common uses:
- top N related rows per left row
- correlated derived tables
- unpacking arrays or JSON per row

Mental model: for each left row, run this right-side query with left-row values.

### Semi Join
PostgreSQL does not have a `SEMI JOIN` keyword in normal SQL syntax, but the concept is important.

A semi join returns left-side rows that have at least one match on the right, without duplicating the left row for multiple matches.

Usually write it with `EXISTS` or sometimes `IN`.

```sql
SELECT c.*
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);
```

Result:

```text
1 | Alice
2 | Bob
```

Why not use `INNER JOIN` here?

```sql
SELECT c.*
FROM customers c
JOIN orders o
  ON c.id = o.customer_id;
```

That would duplicate Alice because she has multiple orders. `EXISTS` expresses the intent more clearly: return customers that have at least one order.

### Anti Join
An anti join returns left-side rows that have no match on the right.

Usually write it with `NOT EXISTS`.

```sql
SELECT c.*
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);
```

Result:

```text
3 | Carol
```

Equivalent pattern:

```sql
SELECT c.*
FROM customers c
LEFT JOIN orders o
  ON c.id = o.customer_id
WHERE o.id IS NULL;
```

Best practice: `NOT EXISTS` is usually clearer and safer than `NOT IN`, especially when `NULL` values are involved.

### Equi Join
An equi join uses equality in the join condition.

```sql
SELECT *
FROM a
JOIN b
  ON a.id = b.id;
```

This is a category, not a separate SQL keyword.

### Non-Equi Join
A non-equi join uses a condition other than equality, such as `<`, `>`, `<=`, `>=`, or `BETWEEN`.

```sql
SELECT *
FROM events e
JOIN pricing p
  ON e.event_date BETWEEN p.start_date AND p.end_date;
```

Common uses:
- temporal joins
- range lookups
- bucketing
- effective-dated dimensions

## Join Conditions: `ON` vs `USING` vs `WHERE`

### `ON`
Most explicit and most flexible.

```sql
SELECT *
FROM a
JOIN b
  ON a.x = b.y;
```

### `USING`
Use when both sides share the same column name.

```sql
SELECT *
FROM a
JOIN b USING (id);
```

### `WHERE`
Old-style inner join syntax:

```sql
SELECT *
FROM a, b
WHERE a.id = b.id;
```

This works for inner joins, but explicit `JOIN ... ON` is usually clearer and safer.

## PostgreSQL Practical Notes

### Joins Can Multiply Rows
If one customer has many orders, joining customers to orders returns multiple rows for that customer.

That is normal join behavior.

### Outer Join Filtering Trap
This query looks like a `LEFT JOIN`:

```sql
SELECT *
FROM customers c
LEFT JOIN orders o
  ON c.id = o.customer_id
WHERE o.total > 50;
```

But it effectively behaves like an inner join for that filter, because rows with no order have `NULL` in `o.total`, and `NULL > 50` is not true.

If you want to preserve all customers and only match qualifying orders, move the filter into the join condition:

```sql
SELECT *
FROM customers c
LEFT JOIN orders o
  ON c.id = o.customer_id
 AND o.total > 50;
```

### `NULL` Does Not Equal `NULL`
Standard equality joins do not match two `NULL` values.

```sql
ON a.col = b.col
```

That does not match rows where both sides are `NULL`.

For a null-safe comparison in PostgreSQL, use:

```sql
ON a.col IS NOT DISTINCT FROM b.col
```

## PostgreSQL Execution Side: Physical Join Algorithms

These are planner strategies, not logical SQL join types. PostgreSQL may execute a logical join using one of these physical methods:

- `Nested Loop`
- `Hash Join`
- `Merge Join`

You usually do not write these directly. You see them in `EXPLAIN` output.

### `Nested Loop`
For each row from one input, PostgreSQL probes the other input for matches.

Often good for:
- a small outer input
- indexed lookups on the inner input

### `Hash Join`
PostgreSQL builds a hash table from one input, then probes it with rows from the other input.

Often good for:
- equality joins
- medium to large unsorted inputs

### `Merge Join`
PostgreSQL reads both inputs in join-key order and merges them.

Often good for:
- inputs already sorted on the join key
- inputs that can be sorted cheaply

These affect performance, not query meaning.

## Compact Cheat Sheet

### Main SQL Join Types
- `INNER JOIN`: only matching rows
- `LEFT JOIN`: all left rows, matched right rows, `NULL` for missing right rows
- `RIGHT JOIN`: all right rows, matched left rows, `NULL` for missing left rows
- `FULL JOIN`: all matches plus all non-matches from both sides
- `CROSS JOIN`: every possible combination

### Important Patterns
- self join
- `LATERAL`
- semi join via `EXISTS`
- anti join via `NOT EXISTS`

### Syntax Helpers
- `ON`: most explicit and flexible
- `USING`: shorthand when join column names match
- `NATURAL`: shorthand for all shared column names, but risky

### Practical Defaults
- use `INNER JOIN` when you only want matches
- use `LEFT JOIN` when you must preserve left-side rows
- use `EXISTS` for semi-join logic
- use `NOT EXISTS` for anti-join logic
- prefer explicit join conditions over `NATURAL JOIN` and old comma syntax
