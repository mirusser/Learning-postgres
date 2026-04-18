## 1. Start with one question
**How is the database getting rows, and is it getting too many too early?**  
That is the core of plan reading: access path, row counts, join shape, sorts, and extra lookups. PostgreSQL and SQL Server both optimize based on estimated cost and row-count estimates, so those are the first things to inspect.

## 2. Read plans in this order
### A. Access path
Ask:
- Is this a **scan** or a **targeted index access**?
- Is it **index-only / covering**, or does it need extra base-table lookups?
- Is the engine using index order, or will it sort later?

Mental model:
```
Best:     narrow index access -> few rows  
Okay:     scan when large % of table is needed  
Worrying: many lookups or scan + sort + late filter
```
### B. Estimated vs actual rows
Ask:
- Did the optimizer guess row counts correctly?
- Is there a big mismatch between **estimated** and **actual** rows?  
    Large mismatches usually point to statistics/selectivity problems, and bad estimates often lead to the wrong join type or access path.

Rule of thumb:
```
Estimated 10, actual 12     -> fine  
Estimated 10, actual 100000 -> major red flag
```

### C. Join order and intermediate row counts
Ask:
- Which table/input is driving the plan?
- Are rows filtered early or late?
- Does the plan create a huge intermediate result before shrinking it again?  
    Good plans usually keep intermediate row counts small.

### D. Expensive extras
Look for:
- explicit `Sort`
- `Hash` on unexpectedly large inputs
- heap/key lookups repeated many times
- spills to disk
- parallelism used to compensate for a bad shape instead of a good one

---

# What “good” usually looks like
```
Selective predicate  
   -> efficient access path  
   -> small join input  
   -> appropriate join method  
   -> no unnecessary sort  
   -> no repeated heap/key lookups
```

Example of a healthy shape:
```
Index Scan / Index Seek  
   -> Nested Loop or Hash Join on small-enough input  
   -> maybe no Sort because index already provides order
```

This is usually better than:
```
Seq/Table Scan  
   -> huge Hash Join  
   -> Sort  
   -> many lookups  
   -> final small result
```

because the second shape touches much more data before reducing it.

---

# Join methods: quick interpretation

## Nested Loop
Best when:
- outer input is small
- inner side can be probed cheaply, often via index

Worry when:
- outer input is much larger than estimated
- inner probe is repeated many times expensively

## Hash Join
Best when:
- joining medium/large unsorted sets
- one side can be hashed efficiently

Worry when:
- hash input is much bigger than expected
- memory pressure or spills appear

## Merge Join
Best when:
- both sides are already sorted on join keys
- or can be sorted cheaply

Worry when:
- large sorts are added just to make it possible

Interview line:
> “I don’t label a join method good or bad in isolation; I check whether it matches the data volume, ordering, and access path.”

---
# Scan vs seek vs index-only
## Scan
A scan is not automatically bad. If you need a large fraction of the table, scanning can be cheaper than many random lookups.
## Seek / narrow index access
Good when predicates are selective and the index matches the filter/join pattern. In PostgreSQL the comparable concept is often an `Index Scan`; in SQL Server people often say `Index Seek`.
## Index-only / covering
Great when the query can be answered from the index alone, avoiding extra heap/base-table lookups. PostgreSQL calls this `Index Only Scan`; SQL Server commonly achieves something similar with covering indexes and included columns.

---
# Sorts: when to care
A sort is often a sign to ask:
- could an index provide the needed order?
- could filtering happen earlier?
- is `ORDER BY ... LIMIT` missing a supporting index?  
    B-tree indexes can often satisfy ordering directly, which may avoid a separate sort step.

---
# Red flags to mention out loud
If you see these, mention them:
- huge **estimated vs actual** row mismatch
- broad scan for a supposedly selective predicate
- many base-table / heap / key lookups
- big sort before `LIMIT`
- join order that explodes rows early
- nested loop on a much larger-than-expected outer input
- “using an index” but still reading too much data

---
# What to say when asked “How do you analyze a slow query?”

Use this structure:
1. **Check the actual execution plan**
2. **Compare estimated vs actual rows**
3. **Inspect access path**: scan, index access, index-only/covering, lookups
4. **Check join order and join type**
5. **Look for unnecessary sorts or repeated lookups**
6. **Decide whether the fix is**
    - better index
    - query rewrite
    - updated statistics
    - reduced selected columns
    - better predicate shape
    - schema/design change

---
# 30-second interview answer

> “I read execution plans in terms of access path and cardinality. First I check whether the engine is scanning too much data or using a narrow index path. Then I compare estimated and actual rows, because bad row estimates often explain a bad plan. After that I look at join order, whether intermediate row counts stay small, and whether there are avoidable costs like sorts or repeated heap/key lookups. Finally I decide whether the problem is indexing, query shape, or bad statistics.”

---
# 10-second compressed version

> “I want the optimizer to touch as little data as possible, as early as possible, and the plan tells me whether that’s happening.”