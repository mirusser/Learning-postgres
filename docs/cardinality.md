In databases, **cardinality** usually means:
- **“how many distinct values”** 
- or more generally **“how many items are involved.”** 

The exact meaning depends on context, most common are:
## 1. Cardinality of a result set
This is just **how many rows** are returned.

Example:
```sql
SELECT * FROM users;
```

If this returns 120 rows, the result set cardinality is **120**.

This matters because PostgreSQL’s query planner tries to **estimate cardinality** to choose a fast execution plan.

Example:
```sql
SELECT * FROM orders WHERE status = 'paid';
```

If PostgreSQL thinks this returns only 10 rows, it may use an index.  
If it thinks it returns 500,000 rows, it may prefer a sequential scan.

---
## 2. Cardinality of a column
This means **how many distinct values** a column has.

Example table:
```
users  
id | country | status  
---+---------+--------  
1  | PL      | active  
2  | DE      | active  
3  | PL      | inactive  
4  | FR      | active
```

For `country`, the distinct values are: `PL, DE, FR`
So the cardinality of `country` here is **3**.

For `status`, the distinct values are:`active, inactive`
So its cardinality is **2**.

This is often described as:
- **high cardinality** = many distinct values, like `email`, `user_id`
- **low cardinality** = few distinct values, like `status`, `is_deleted`

Examples:
- `email` → very high cardinality
- `country_code` → medium cardinality
- `gender` or `status` → low cardinality

Why it matters:
- indexing behavior
- query planning
- compression
- grouping and aggregation

A high-cardinality column is often more selective in a `WHERE` clause.
High-cardinality columns are often better index candidates than very low-cardinality ones.

Example:
```sql
SELECT *  
FROM users  
WHERE email = 'a@example.com';
```

This likely matches one row, so an index is very useful.

But:
```sql
SELECT *  
FROM users  
WHERE status = 'active';
```

If 95% of rows are active, that predicate is not very selective, so an index may help less.

---
## 3. Cardinality in relationships
In database design, cardinality describes how tables relate:
- **one-to-one**
- **one-to-many**
- **many-to-many**
### One-to-one
One row in A matches one row in B.

Example:
- `users`
- `user_profiles`

One user has one profile.
### One-to-many
One row in A matches many rows in B.

Example:
```sql
CREATE TABLE customers (  
    id serial PRIMARY KEY,  
    name text  
);  
  
CREATE TABLE orders (  
    id serial PRIMARY KEY,  
    customer_id int REFERENCES customers(id),  
    total numeric  
);
```

Here:
- one `customer`
- many `orders`

A customer can have many orders, but each order belongs to one customer.
### Many-to-many
Many rows in A match many rows in B.

Students and courses:
```sql
CREATE TABLE students (  
    id serial PRIMARY KEY,  
    name text  
);  
  
CREATE TABLE courses (  
    id serial PRIMARY KEY,  
    title text  
);  
  
CREATE TABLE student_courses (  
    student_id int REFERENCES students(id),  
    course_id int REFERENCES courses(id),  
    PRIMARY KEY (student_id, course_id)  
);
```

A student can take many courses, and a course can have many students.

---
## 4. The `cardinality()` function for arrays
PostgreSQL also has a built-in function called `cardinality()` for arrays.

It returns the **total number of elements** in an array.

Example:
```sql
SELECT cardinality(ARRAY[10, 20, 30]);
```
Result: `3`

For multidimensional arrays:
```sql
SELECT cardinality('{{1,2},{3,4}}'::int[]);
```
Result: `4`

Because there are 4 total elements.

---
## Quick summary
In PostgreSQL, “cardinality” usually means one of these:
- **row count** of a query result
- **number of distinct values** in a column
- **relationship type** between tables
- **number of elements in an array** when using `cardinality()`
## Small practical examples
Distinct values in a column:
```sql
SELECT COUNT(DISTINCT status) FROM orders;
```

Array size:
```sql
SELECT cardinality(tags) FROM articles;
```

Rows returned by a filter:
```sql
SELECT COUNT(*) FROM orders WHERE total > 100;
```

Relationship example:
- one user → many posts
- many posts → one user

---

## Cardinality vs selectivity
These are closely related but not identical.

**Cardinality** is about distinctness or row counts.  
**Selectivity** is about how much a condition narrows the data.

For example:
- `status` has low cardinality: only 3 possible values
- a condition like `status = 'archived'` might still be selective if only 0.1% of rows are archived

So low cardinality does not always mean “useless,” but often it means “less selective on average.”

### In PostgreSQL specifically
PostgreSQL tracks statistics about columns, including approximate distinct counts, to estimate cardinality during planning. Those stats are refreshed by `ANALYZE` and autovacuum/analyze.

That is why stale statistics can cause bad execution plans: PostgreSQL guesses the wrong cardinality, then picks the wrong strategy.
#### Tiny examples

##### High-cardinality column
```
email  
---------  
a@x.com  
b@x.com  
c@x.com  
d@x.com
```
Nearly every row is different.

##### Low-cardinality column
```
status  
--------  
new  
new  
done  
new  
done
```
Only a few distinct values.

---
## The shortest practical meaning
In day-to-day PostgreSQL:
- for **schema/data**, cardinality usually means **number of distinct values**
- for **relationships**, it means **one-to-one / one-to-many / many-to-many**
- for **execution plans**, it means **number of rows expected or returned**