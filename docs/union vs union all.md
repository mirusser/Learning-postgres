`UNION` combines result sets and **removes duplicate rows**.

`UNION ALL` combines result sets and **keeps all rows**, including duplicates.

Example:
```sql
SELECT 1  
UNION  
SELECT 1;
```

Result: 
```
1
```

But:
```sql
SELECT 1  
UNION ALL  
SELECT 1;
```

Result:
```
1  
1
```


In PostgreSQL, that means:
- Use `UNION` when you want distinct rows across both queries.
- Use `UNION ALL` when duplicates are acceptable or desired.

Performance-wise, `UNION ALL` is usually faster because PostgreSQL does not need to do the extra work of deduplicating rows.

---

A couple of rules:
- Both queries must return the same number of columns.
- Corresponding columns must have compatible data types.

Example with tables:

This gives unique emails only:
```sql
SELECT email FROM customers  
UNION  
SELECT email FROM leads;
```


This gives every email from both tables, even if the same email appears in both:
```sql
SELECT email FROM customers  
UNION ALL  
SELECT email FROM leads;
```


**A practical rule**: default to `UNION ALL` unless you specifically need duplicate removal.