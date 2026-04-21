# Window Functions in PostgreSQL

## Summary
Window functions calculate values across related rows without collapsing them into one row per group.

That is the key difference from `GROUP BY`:
- `GROUP BY` reduces many rows to one row per group
- window functions keep every original row and add calculated values beside it

## Base Example Table

This document uses one sample table throughout:

```text
employees
---------
id | name  | department_id | salary
1  | Alice | 1             | 5000
2  | Bob   | 1             | 6000
3  | Carol | 1             | 6000
4  | David | 2             | 4000
5  | Emma  | 2             | 4500
```

Queries below use a top-level `ORDER BY` when the output order matters.

Important: `ORDER BY` inside `OVER (...)` controls how the window function works. It does not, by itself, guarantee the final output order.

## Basic Shape

A window function looks like this:

```text
function_name(...) OVER (...)
```

Examples:

```text
avg(salary) OVER (...)
row_number() OVER (...)
rank() OVER (...)
sum(salary) OVER (...)
lag(salary) OVER (...)
```

The `OVER (...)` clause defines how the function should look across related rows.

## The Three Core Pieces

### `OVER (...)`
This turns an aggregate or built-in window function into a window calculation.

Examples:

```sql
avg(salary) OVER ()
row_number() OVER (PARTITION BY department_id ORDER BY salary DESC)
```

### `PARTITION BY`
This splits rows into partitions for the calculation.

```sql
avg(salary) OVER (PARTITION BY department_id)
```

Meaning:
- for each employee row
- look at rows in the same department
- calculate the value inside that department

If you omit `PARTITION BY`, the whole result set is one partition.

### `ORDER BY`
This defines order inside each partition.

```sql
row_number() OVER (PARTITION BY department_id ORDER BY salary DESC)
```

Meaning:
- inside each department
- process rows from highest salary to lowest

This matters for ranking functions, `lag`, `lead`, running totals, and other order-sensitive calculations.

## Compare with `GROUP BY`

### `GROUP BY`

```sql
SELECT department_id,
       round(avg(salary), 2) AS dept_avg_salary
FROM employees
GROUP BY department_id
ORDER BY department_id;
```

Result:

```text
department_id | dept_avg_salary
1             | 5666.67
2             | 4250.00
```

You get one row per department.

### Window Function

```sql
SELECT id,
       name,
       department_id,
       salary,
       round(avg(salary) OVER (PARTITION BY department_id), 2) AS dept_avg_salary
FROM employees
ORDER BY department_id, id;
```

Result:

```text
id | name  | department_id | salary | dept_avg_salary
1  | Alice | 1             | 5000   | 5666.67
2  | Bob   | 1             | 6000   | 5666.67
3  | Carol | 1             | 6000   | 5666.67
4  | David | 2             | 4000   | 4250.00
5  | Emma  | 2             | 4500   | 4250.00
```

You keep one row per employee and add the department average beside each row.

## Core Examples

### Department Average Beside Each Employee

```sql
SELECT e.id,
       e.name,
       e.department_id,
       e.salary,
       round(avg(e.salary) OVER (PARTITION BY e.department_id), 2) AS dept_avg_salary
FROM employees e
ORDER BY e.department_id, e.id;
```

Result:

```text
id | name  | department_id | salary | dept_avg_salary
1  | Alice | 1             | 5000   | 5666.67
2  | Bob   | 1             | 6000   | 5666.67
3  | Carol | 1             | 6000   | 5666.67
4  | David | 2             | 4000   | 4250.00
5  | Emma  | 2             | 4500   | 4250.00
```

How to read it:
- take the current employee row
- look at all rows in the same `department_id`
- calculate the average salary for that partition
- show it on each row

### Company-Wide Average Beside Each Employee

```sql
SELECT e.id,
       e.name,
       e.salary,
       round(avg(e.salary) OVER (), 2) AS company_avg_salary
FROM employees e
ORDER BY e.id;
```

Result:

```text
id | name  | salary | company_avg_salary
1  | Alice | 5000   | 5100.00
2  | Bob   | 6000   | 5100.00
3  | Carol | 6000   | 5100.00
4  | David | 4000   | 5100.00
5  | Emma  | 4500   | 5100.00
```

`OVER ()` means: use the whole result set as one partition.

## Ranking Patterns

### `row_number()`, `rank()`, and `dense_rank()`

```sql
SELECT e.name,
       e.department_id,
       e.salary,
       row_number() OVER (
           PARTITION BY e.department_id
           ORDER BY e.salary DESC, e.id
       ) AS salary_row_number,
       rank() OVER (
           PARTITION BY e.department_id
           ORDER BY e.salary DESC
       ) AS salary_rank,
       dense_rank() OVER (
           PARTITION BY e.department_id
           ORDER BY e.salary DESC
       ) AS salary_dense_rank
FROM employees e
ORDER BY e.department_id, e.salary DESC, e.id;
```

Result:

```text
name  | department_id | salary | salary_row_number | salary_rank | salary_dense_rank
Bob   | 1             | 6000   | 1                 | 1           | 1
Carol | 1             | 6000   | 2                 | 1           | 1
Alice | 1             | 5000   | 3                 | 3           | 2
Emma  | 2             | 4500   | 1                 | 1           | 1
David | 2             | 4000   | 2                 | 2           | 2
```

How to interpret it:
- `row_number()` always gives distinct numbers
- `rank()` gives the same rank to ties and leaves gaps
- `dense_rank()` gives the same rank to ties but does not leave gaps

Important: `row_number()` is only deterministic for ties if you add a tie-breaker such as `ORDER BY salary DESC, id`.

### Top Earner Per Department

```sql
SELECT id,
       name,
       department_id,
       salary
FROM (
    SELECT e.*,
           row_number() OVER (
               PARTITION BY e.department_id
               ORDER BY e.salary DESC, e.id
           ) AS rn
    FROM employees e
) t
WHERE rn = 1
ORDER BY department_id, id;
```

Result:

```text
id | name | department_id | salary
2  | Bob  | 1             | 6000
5  | Emma | 2             | 4500
```

This keeps one row per department. Because `row_number()` uses `id` as a tie-breaker, Bob is chosen over Carol.

If you want all tied top earners, use `rank()` or `dense_rank()` and filter on `= 1`.

### Second-Highest Distinct Salary Per Department

```sql
SELECT id,
       name,
       department_id,
       salary
FROM (
    SELECT e.*,
           dense_rank() OVER (
               PARTITION BY e.department_id
               ORDER BY e.salary DESC
           ) AS salary_rank
    FROM employees e
) t
WHERE salary_rank = 2
ORDER BY department_id, id;
```

Result:

```text
id | name  | department_id | salary
1  | Alice | 1             | 5000
4  | David | 2             | 4000
```

`dense_rank()` is often the right choice here because tied top salaries still leave the next distinct salary at rank 2.

## Filtering with a Subquery

### Employees Above Department Average

```sql
SELECT id,
       name,
       department_id,
       salary,
       round(dept_avg_salary, 2) AS dept_avg_salary
FROM (
    SELECT e.id,
           e.name,
           e.department_id,
           e.salary,
           avg(e.salary) OVER (PARTITION BY e.department_id) AS dept_avg_salary
    FROM employees e
) t
WHERE salary > dept_avg_salary
ORDER BY department_id, id;
```

Result:

```text
id | name  | department_id | salary | dept_avg_salary
2  | Bob   | 1             | 6000   | 5666.67
3  | Carol | 1             | 6000   | 5666.67
5  | Emma  | 2             | 4500   | 4250.00
```

This is a very common pattern:
- compute the window value in an inner query
- filter on that value in the outer query

## Running Totals

```sql
SELECT e.id,
       e.name,
       e.salary,
       sum(e.salary) OVER (
           ORDER BY e.id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM employees e
ORDER BY e.id;
```

Result:

```text
id | name  | salary | running_total
1  | Alice | 5000   | 5000
2  | Bob   | 6000   | 11000
3  | Carol | 6000   | 17000
4  | David | 4000   | 21000
5  | Emma  | 4500   | 25500
```

This gives a cumulative total from the first row up to the current row in `id` order.

If you partition too, the running total restarts inside each partition.

## Looking at Previous and Next Rows

### `lag()` and `lead()`

```sql
SELECT e.name,
       e.department_id,
       e.salary,
       lag(e.salary) OVER (
           PARTITION BY e.department_id
           ORDER BY e.salary DESC, e.id
       ) AS previous_salary,
       lead(e.salary) OVER (
           PARTITION BY e.department_id
           ORDER BY e.salary DESC, e.id
       ) AS next_salary
FROM employees e
ORDER BY e.department_id, e.salary DESC, e.id;
```

Result:

```text
name  | department_id | salary | previous_salary | next_salary
Bob   | 1             | 6000   | NULL            | 6000
Carol | 1             | 6000   | 6000            | 5000
Alice | 1             | 5000   | 6000            | NULL
Emma  | 2             | 4500   | NULL            | 4000
David | 2             | 4000   | 4500            | NULL
```

Useful for:
- comparing the current row to the previous one
- comparing the current row to the next one
- spotting changes or trends

By default, `lag()` and `lead()` use an offset of 1 and return `NULL` when there is no previous or next row.

## PostgreSQL Practical Notes

### Where Window Functions Are Allowed
In normal query syntax, window functions can appear in:
- the `SELECT` list
- the query's `ORDER BY`

They cannot be used directly in:
- `WHERE`
- `GROUP BY`
- `HAVING`

That is why filtering on a window result usually needs a subquery or CTE.

### Window Functions See the Filtered Virtual Table
Window functions operate on the rows left after `FROM`, `WHERE`, `GROUP BY`, and `HAVING` have already done their work at that query level.

If a row is removed by `WHERE`, the window function does not see it.

### Default Frame Can Change Ordered Aggregate Results
For aggregate window functions such as `sum(...) OVER (...)`, adding `ORDER BY` changes the default frame.

In PostgreSQL, the default frame with `ORDER BY` runs from the start of the partition through the current row, including peers with the same ordering value.

That means:
- `sum(x) OVER ()` usually gives the full-partition total on every row
- `sum(x) OVER (ORDER BY some_column)` usually gives running-total behavior
- if `some_column` has ties, peer rows can share the same running total

Using a unique order key or an explicit `ROWS` frame makes the intent clearer.

## Mental Model

Think of it like this:
- `GROUP BY` says: combine rows
- window functions say: look across related rows, but keep each row

That is why window functions are good for:
- averages beside each row
- ranking within groups
- top N per group
- running totals
- previous and next row comparisons

## Quick Rules

- `OVER ()` means one partition containing all rows
- `PARTITION BY ...` splits rows into independent partitions
- `ORDER BY ...` inside `OVER` defines processing order for the window function
- use a top-level `ORDER BY` if you care about final display order
- use an outer query when you need to filter by a window result

## When to Use Them

Use window functions when you want:
- row details and group statistics together
- ranking within categories
- top 1 or top N per group
- running or cumulative calculations
- previous or next row comparisons

Do not use them when a plain `GROUP BY` already gives exactly the result you need.
