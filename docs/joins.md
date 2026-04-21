## What a join is
A **join** combines rows from two tables based on a condition.

Example tables:
```sql
customers  
---------  
id | name  
1  | Alice  
2  | Bob  
3  | Carol  
```
  
```sql
orders  
------  
id | customer_id | total  
10 | 1           | 50  
11 | 1           | 80  
12 | 2           | 30
```

A typical join condition is:
```sql
customers.id = orders.customer_id
```

---
# 1. INNER JOIN
An **INNER JOIN** returns only rows where the join condition matches in both tables.
```sql
SELECT c.name, o.id, o.total  
FROM customers c  
INNER JOIN orders o  
  ON c.id = o.customer_id;
```

Result:
```
Alice | 10 | 50  
Alice | 11 | 80  
Bob   | 12 | 30
```
Carol is missing because she has no matching order.
### Mental model
“Keep only the intersection.”
### Notes
- `JOIN` by itself usually means `INNER JOIN`
- most commonly used join

---
# 2. LEFT JOIN / LEFT OUTER JOIN
A **LEFT JOIN** returns:
- all rows from the left table
- matching rows from the right table
- `NULL`s for right-table columns when there is no match

```sql
SELECT c.name, o.id, o.total  
FROM customers c  
LEFT JOIN orders o  
  ON c.id = o.customer_id;
```

Result:
```
Alice | 10 | 50  
Alice | 11 | 80  
Bob   | 12 | 30  
Carol | NULL | NULL
```
Carol appears because all rows from `customers` are preserved.
### Mental model
“Keep everything from the left, match what you can from the right.”

###  Notes
- `LEFT JOIN` vs `LEFT OUTER JOIN`
Same thing. `OUTER` is optional.

---
# 3. RIGHT JOIN / RIGHT OUTER JOIN
A **RIGHT JOIN** is the mirror image of a left join.

It returns:
- all rows from the right table
- matching rows from the left table
- `NULL`s for left-table columns when there is no match

Example with an unmatched order:
```
orders  
------  
id | customer_id | total  
10 | 1           | 50  
11 | 1           | 80  
12 | 2           | 30  
13 | 99          | 20
```

Query:
```sql
SELECT c.name, o.id, o.total  
FROM customers c  
RIGHT JOIN orders o  
  ON c.id = o.customer_id;
```

Result:
```
Alice | 10 | 50  
Alice | 11 | 80  
Bob   | 12 | 30  
NULL  | 13 | 20
```

### Mental model
“Keep everything from the right, match what you can from the left.”

### Practical note
People often avoid `RIGHT JOIN` because the same logic can usually be written more clearly as a `LEFT JOIN` by swapping table order.

---
# 4. FULL JOIN / FULL OUTER JOIN
A **FULL JOIN** returns:
- all matching rows
- all unmatched rows from the left table
- all unmatched rows from the right table

Where no match exists, the missing side is filled with `NULL`s.

```sql
SELECT c.name, o.id, o.total  
FROM customers c  
FULL JOIN orders o  
  ON c.id = o.customer_id;
```

Using the unmatched order `customer_id = 99`, result:
```
Alice | 10   | 50  
Alice | 11   | 80  
Bob   | 12   | 30  
Carol | NULL | NULL  
NULL  | 13   | 20
```

### Mental model
“Keep everything from both sides.”

---
# 5. CROSS JOIN
A **CROSS JOIN** returns the Cartesian product.

That means:
- every row from the first table
- combined with every row from the second table

If table A has 3 rows and table B has 4 rows, the result has 12 rows.

Example:
```
colors  
------  
red  
blue  
```

```
sizes  
-----  
S  
M  
L
```  

Query:
```sql
SELECT *  
FROM colors  
CROSS JOIN sizes;
```

Result:
```
red  | S  
red  | M  
red  | L  
blue | S  
blue | M  
blue | L

```

### Mental model
“All combinations.”

### Important
No `ON` clause is used with a normal cross join.

You can also accidentally create a cross join by forgetting a join condition:
```sql
SELECT *  
FROM a, b;
```

or
```sql
SELECT *  
FROM a  
JOIN b ON TRUE;
```

That may explode row counts.

---
# 6. SELF JOIN
A **self join** is not a separate SQL keyword. It is a pattern: a table joined to itself.

Useful for:
- parent/child relationships
- employee/manager relationships
- comparing rows within one table

Example:
```sql
employees  
---------  
id | name  | manager_id  
1  | CEO   | NULL  
2  | Ann   | 1  
3  | Ben   | 1  
4  | Cara  | 2
```


Query:
```sql
SELECT e.name AS employee,  
       m.name AS manager  
FROM employees e  
LEFT JOIN employees m  
  ON e.manager_id = m.id;
```

Result:
```
CEO  | NULL  
Ann  | CEO  
Ben  | CEO  
Cara | Ann
```

### Mental model
“Treat one table as if it were two roles.”

Aliases are essential in self joins.

---

# 7. NATURAL JOIN
A **NATURAL JOIN** automatically joins tables using all columns with the same names in both tables.

Example:
```sql
SELECT *  
FROM a  
NATURAL JOIN b;
```

If both tables have columns named `id` and `code`, PostgreSQL joins on both.
### Why this is risky
It can be convenient, but it is often discouraged because:
- the join condition is implicit
- schema changes can silently change query behavior
- it is easy to join on more columns than intended

Most production SQL prefers explicit joins:
```sql
SELECT *  
FROM a  
JOIN b  
  ON a.id = b.id;
```
### Important
`NATURAL JOIN` can combine with join types:
- `NATURAL JOIN`
- `NATURAL LEFT JOIN`
- `NATURAL RIGHT JOIN`
- `NATURAL FULL JOIN`

But explicit `ON` conditions are usually safer.

---
# 8. JOIN ... USING
`USING` is not a different join type either, but a join syntax.

Instead of:
```sql
SELECT *  
FROM customers c  
JOIN orders o  
  ON c.id = o.customer_id;
```

You use `USING` when both join columns have the same name:
```sql
SELECT *  
FROM a  
JOIN b  
  USING (id);
```

This means:
```
ON a.id = b.id
```

### Special behavior
With `USING`, the joined column appears only once in the output.

Example:
```
table_a  
-------  
id | val_a  
```

```
table_b  
-------  
id | val_b
```

Query:
```sql
SELECT *  
FROM table_a  
JOIN table_b USING (id);
```

Output columns:
```
id | val_a | val_b
```
instead of two separate `id` columns.

### Good use case
- Clean syntax when the common key has the same name in both tables.

---
# 9. LATERAL JOIN
A **LATERAL** join lets a subquery on the right side refer to columns from the left side.

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
The subquery can use `c.id`, which comes from the left table.

### Why lateral is useful
It lets the right-side subquery run “per row” of the left table.

Common uses:
- top N related rows per row
- correlated derived tables
- unpacking arrays or JSON per row

### Mental model
“For each left row, run this right-side query using left-row values.”

---
# 10. SEMI JOIN
PostgreSQL does not have a `SEMI JOIN` keyword in normal SQL syntax, but the concept exists.

A semi join returns left-table rows that have at least one match in the right table, without duplicating left rows for multiple matches.

Usually written with `EXISTS` or `IN`.

Example:
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
```
Alice  
Bob
```
Carol is excluded because she has no order.

### Why not use INNER JOIN here?

Because this:
```sql
SELECT c.*  
FROM customers c  
JOIN orders o  
  ON c.id = o.customer_id;
```
would duplicate Alice if she has multiple orders.

`EXISTS` expresses the intent better:  
“return customers that have at least one order.”

---
# 11. ANTI JOIN
Again, not a keyword in standard PostgreSQL SQL syntax, but a very important concept.

An anti join returns rows from the left table that have **no** match in the right table.

Usually written with `NOT EXISTS`.
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
```
Carol
```

### Left join equivalent

You may also see:
```sql
SELECT c.*  
FROM customers c  
LEFT JOIN orders o  
  ON c.id = o.customer_id  
WHERE o.id IS NULL;
```
This also finds customers with no orders.

### Best practice
`NOT EXISTS` is often clearer and safer than `NOT IN`, especially with `NULL`s.

---
# 12. Equi join
An **equi join** means the join condition uses equality.

Example:
```sql
SELECT *  
FROM a  
JOIN b  
  ON a.id = b.id;
```

This is not a separate SQL join keyword. It is just a category.

Most joins in real schemas are equi joins.

---
# 13. Non-equi join
A **non-equi join** uses some condition other than equality, such as `<`, `>`, `BETWEEN`, or ranges.

Example:
```sql
SELECT *  
FROM events e  
JOIN pricing p  
  ON e.event_date BETWEEN p.start_date AND p.end_date;
```
This joins rows based on a range match rather than exact equality.

Useful for:
- temporal joins
- range tables
- bucket lookups
- effective-dated dimensions

---
# Visual summary

Suppose:

Left table:
```
id  
--  
1  
2  
3
```

Right table:
```
id  
--  
2  
3  
4
```

Then:
## INNER JOIN
Only matches:
```
2  
3
```
## LEFT JOIN
All left plus matches:
```
1  
2  
3
```
with right side `NULL` for 1.
## RIGHT JOIN
All right plus matches:
```
2  
3  
4
```
with left side `NULL` for 4.

## FULL JOIN
Everything:
```
1  
2  
3  
4
```
with `NULL`s where no match exists.
## CROSS JOIN
All combinations:
```
1-2  
1-3  
1-4  
2-2  
2-3  
2-4  
3-2  
3-3  
3-4
```

---
# Join conditions: ON vs USING vs WHERE

## `ON`

Most explicit and flexible:
```sql
SELECT *  
FROM a  
JOIN b  
  ON a.x = b.y;
```

## `USING`
Only when column names are the same:
```sql
SELECT *  
FROM a  
JOIN b USING (id);
```

## `WHERE`
Old-style syntax:
```sql
SELECT *  
FROM a, b  
WHERE a.id = b.id;
```

This works for inner joins, but is generally less clear and easier to get wrong. Modern SQL prefers explicit `JOIN ... ON`.

---
# Important PostgreSQL practical notes

## 1. Joins can multiply rows
If one customer has many orders, joining customers to orders returns multiple rows for that customer.

This is expected.

## 2. Outer join filtering trap

This is very common:
```sql
SELECT *  
FROM customers c  
LEFT JOIN orders o  
  ON c.id = o.customer_id  
WHERE o.total > 50;
```

This can effectively turn the left join into an inner join, because rows with no order have `NULL` in `o.total`, and `NULL > 50` is not true.

If you want to preserve all customers and only join qualifying orders, put the condition in `ON`:
```sql
SELECT *  
FROM customers c  
LEFT JOIN orders o  
  ON c.id = o.customer_id  
 AND o.total > 50;
```
That is a very important distinction.

## 3. `NULL` does not equal `NULL`
Normal equality joins do not match `NULL` values.
```
ON a.col = b.col
```
does not match rows where both are `NULL`.

For null-safe comparison in PostgreSQL, use:
```sql
ON a.col IS NOT DISTINCT FROM b.col
```

---
# PostgreSQL execution side: physical join algorithms

These are not SQL join types, but PostgreSQL may implement a join using one of these strategies:
- **Nested Loop Join**
- **Hash Join**
- **Merge Join**

These are execution methods chosen by the planner, not something you usually write directly.
## Nested Loop
For each row in one input, scan matching rows in the other.

Good for:
- small inputs
- indexed lookups

## Hash Join
Build a hash table from one side, probe from the other.

Good for:
- equality joins
- medium/large sets

## Merge Join
Sort both sides, then merge them.

Good for:
- sorted inputs
- range of larger join tasks, especially equi joins

These are about performance, not SQL semantics.

---
# Best practices
Use:
- `INNER JOIN` when you only want matches
- `LEFT JOIN` when you must preserve all left rows
- `EXISTS` for semi-join logic
- `NOT EXISTS` for anti-join logic
- explicit `ON` conditions for clarity

Avoid overusing:
- `NATURAL JOIN`
- old comma-join syntax
- `RIGHT JOIN` when a `LEFT JOIN` rewrite is clearer

---
# Compact cheat sheet

## Main SQL join types
- `INNER JOIN`
- `LEFT [OUTER] JOIN`
- `RIGHT [OUTER] JOIN`
- `FULL [OUTER] JOIN`
- `CROSS JOIN`
## Important patterns
- self join
- lateral join
- semi join via `EXISTS`
- anti join via `NOT EXISTS`
## Syntax helpers
- `ON`
- `USING`
- `NATURAL`
## Conceptual categories
- equi join
- non-equi join