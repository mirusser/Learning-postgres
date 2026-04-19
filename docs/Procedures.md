In PostgreSQL, a stored procedure usually looks like this:

```sql
CREATE [OR REPLACE] PROCEDURE procedure_name(
    [IN | OUT | INOUT] param_name data_type [, ...]
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- local variables
BEGIN
    -- statements
END;
$$;
```

You run it with `CALL procedure_name(...)`, not `SELECT`. A procedure does not return a normal value the way a function does, but it can send data back through `OUT` or `INOUT` parameters. PostgreSQL supports argument modes like `IN`, `OUT`, `INOUT`, and `VARIADIC`. ([postgresql.org](https://www.postgresql.org/docs/current/sql-createprocedure.html))

Here is the simplest mental model:
- `CREATE PROCEDURE` defines it.
- `LANGUAGE plpgsql` means the body uses PostgreSQL’s procedural language.
- `DECLARE` is optional and holds local variables.
- `BEGIN ... END` is the executable block.
- `CALL` executes it. ([postgresql.org](https://www.postgresql.org/docs/current/sql-createprocedure.html))

### 1. Very basic procedure

```sql
CREATE OR REPLACE PROCEDURE say_hello()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Hello from PostgreSQL procedure';
END;
$$;

CALL say_hello();
```

This is a tiny PL/pgSQL procedure. It has no parameters and just prints a notice.

### 2. Procedure with input parameters

```sql
CREATE OR REPLACE PROCEDURE add_employee(
    IN p_name text,
    IN p_salary numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees(name, salary)
    VALUES (p_name, p_salary);
END;
$$;

CALL add_employee('Alice', 5000);
```

This is the common pattern for “do some work” procedures: accept inputs, run SQL statements, finish.

### 3. Procedure with local variables and logic

PL/pgSQL supports `DECLARE`, `IF`, `CASE`, loops, and more inside the block. ([postgresql.org](https://www.postgresql.org/docs/current/plpgsql-control-structures.html))

```sql
CREATE OR REPLACE PROCEDURE give_bonus(
    IN p_employee_id int,
    IN p_bonus numeric
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_salary numeric;
BEGIN
    SELECT salary
    INTO v_current_salary
    FROM employees
    WHERE id = p_employee_id;

    IF v_current_salary IS NULL THEN
        RAISE EXCEPTION 'Employee % not found', p_employee_id;
    END IF;

    UPDATE employees
    SET salary = salary + p_bonus
    WHERE id = p_employee_id;
END;
$$;

CALL give_bonus(10, 750);
```

That example shows the usual shape of a real procedure:
- read something into a variable,
- check a condition,
- update data.

### 4. Procedure with `INOUT`

A procedure itself does not return a normal scalar result, but `OUT` and `INOUT` parameters can carry values back. PostgreSQL’s docs show this pattern with `CALL`. ([postgresql.org](https://www.postgresql.org/docs/current/sql-call.html))

```sql
CREATE OR REPLACE PROCEDURE triple(INOUT x int)
LANGUAGE plpgsql
AS $$
BEGIN
    x := x * 3;
END;
$$;

CALL triple(5);
```

That call returns a row containing the final value of `x`. In plain SQL, `CALL` returns a result row when the procedure has output parameters. ([postgresql.org](https://www.postgresql.org/docs/current/sql-call.html))

Inside PL/pgSQL, you would call it like this:
```sql
DO $$
DECLARE
    myvar int := 5;
BEGIN
    CALL triple(myvar);
    RAISE NOTICE 'myvar = %', myvar;
END;
$$;
```

That exact calling style for `OUT`/`INOUT` parameters is documented by PostgreSQL. ([postgresql.org](https://www.postgresql.org/docs/current/plpgsql-control-structures.html))

### 5. SQL-language procedure

A procedure does not have to be `plpgsql`. PostgreSQL also supports `LANGUAGE SQL`, including a `BEGIN ATOMIC ... END` body for SQL procedures. ([postgresql.org](https://www.postgresql.org/docs/current/sql-createprocedure.html))

```sql
CREATE OR REPLACE PROCEDURE insert_two_rows(a integer, b integer)
LANGUAGE SQL
BEGIN ATOMIC
    INSERT INTO numbers_table(value) VALUES (a);
    INSERT INTO numbers_table(value) VALUES (b);
END;

CALL insert_two_rows(1, 2);
```

### Procedure vs function
A practical rule:
- Use a **function** when you want something you can call in `SELECT`.
- Use a **procedure** when you want to run an operation with `CALL`. PostgreSQL explicitly says functions are called with `SELECT`, while procedures are called with `CALL`. ([postgresql.org](https://www.postgresql.org/docs/current/sql-call.html))

### Transaction note
Procedures are also the PostgreSQL object type tied to `CALL`, and transaction control has special rules: if you execute `CALL` inside an existing transaction block, the called procedure cannot run transaction-control statements such as `COMMIT` or `ROLLBACK`. ([postgresql.org](https://www.postgresql.org/docs/current/sql-call.html))

A good starter template to copy is:

```sql
CREATE OR REPLACE PROCEDURE procedure_name(
    IN p_id int,
    IN p_value text
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM some_table
        WHERE id = p_id
    )
    INTO v_exists;

    IF v_exists THEN
        UPDATE some_table
        SET value = p_value
        WHERE id = p_id;
    ELSE
        INSERT INTO some_table(id, value)
        VALUES (p_id, p_value);
    END IF;
END;
$$;
```

And then:
```sql
CALL procedure_name(1, 'new value');
```

