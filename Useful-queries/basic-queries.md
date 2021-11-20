# Basic queries

- Create database:
  ```sql
  CREATE DATABASE [database_name];
  ```
- Drop\delete database:
  ```sql
  DROP DATABASE [database_name];
  ```
  e.g.
  ```sql
  DROP DATABASE my_database;
  ```
- Create table:
  ```sql
  CREATE TABLE [table_name] ([column_name] [data_type], ...);
  ```
  e.g.
  ```sql
  CREATE TABLE my_table (id INT, name VARCHAR(255));
  ```
- Create table with constraints:
  ```sql
  CREATE TABLE [table_name] ([column_name] [data_type] [constraints], ...)
  ```
  e.g.
  ```sql
  CREATE TABLE person (
      id BIGSERIAL NOT NULL PRIMARY KEY,
      first_name VARCHAR(255) NOT NULL,
      last_name VARCHAR(255) NOT NULL,
      gender VARCHAR(5) NOT NULL,
      date_of_birth DATE NOT NULL
  );
  ```
- drop/delete table:
  ```sql
  DROP TABLE [table_name];
  ```
  e.g.
  ```sql
  DROP TABLE person;
  ```
- insert/add records into table:
  ```sql
  INSERT INTO [table_name] (
      [column_name],
      [column_name],
      ...)
  VALUES (
      [value],
      [value],
      ...);
  ```
  e.g.
  ```sql
  INSERT INTO person (
      first_name,
      last_name,
      gender,
      date_of_birth)
  VALUES(
      'John',
      'Doe',
      'Male'
      DATE '1988-01-09');
  ```
- show all content of a table:
  ```sql
  SELECT * FROM  [table_name];
  ```
- show certain number of rows from a table:
  ```sql
  SELECT * FROM [table_name] LIMIT [number_of_rows];
  ```
  e.g.
  ```sql
  SELECT * FROM person LIMIT 10;
  SELECT * FROM person FETCH FIRST 10 ROWS ONLY;
  ```
- show content of a table and skip certain number of rows:
  ```sql
  SELECT * FROM [table_name] OFFSET [number_of_rows];
  ```
  e.g.
  ```sql
  SELECT * FROM person OFFSET 5;
  ```
- change column type:
  ```sql
   ALTER TABLE [table_name] ALTER COLUMN [column_name] TYPE [data_type];
  ```
  or
  ```sql
  ALTER TABLE [table_name] ALTER COLUMN [column_name] TYPE [data_type] USING [column_name]::[data_type];
  ```
  e.g.
  ```sql
  ALTER TABLE person ALTER COLUMN gender TYPE VARCHAR(10);
  ```
- delete/remove records:
  ```sql
  DELETE FROM [table_name] WHERE [condition];
  ```
  e.g.
  ```sql
  DELETE FROM person WHERE Id = 12;
  ```
- update records:

  ```sql
  UPDATE [table_name]
  SET
      [column_name] = [value],
      [another_column_name] = [another_value],
      ...
  WHERE [condition];
  ```

  e.g.

  ```sql
  UPDATE person
  SET
      email = 'example@example.com`
  WHERE Id = 12;
  ```

- ignore case sensitivity while filtering a string
  ```sql
  iLIKE
  ```
  e.g.
  ```sql
  SELECT country FROM person WHERE country iLIKE '%germ%';
  ```
- coalesce - return first non-null value
  ```sql
  COALESCE([argument_1], [argument_2], ...)
  ```
  e.g.
  ```sql
  SELECT COALESCE(country, 'Unknown') FROM person;
  ```
  - coalesce with nullif e.g.
  ```sql
  select coalesce(10/nullif(0,0), 0);
  ```
- get current timestamp (full date):
  ```sql
  SELECT NOW();
  ```
- get current date:
  ```sql
  SELECT NOW()::DATE;
  ```
- get current time:
  ```sql
  SELECT NOW()::TIME;
  ```
- adding and subtracting with dates e.g.
  ```sql
  SELECT NOW() - INTERVAL '1 YEAR';
  SELECT NOW() - INTERVAL '10 YEARS';
  SELECT NOW() - INTERVAL '5 MONTHS';
  SELECT NOW() - INTERVAL '1 MONTH';
  SELECT NOW() - INTERVAL '23 DAYS';
  SELECT NOW() + INTERVAL '53 DAY';
  SELECT (NOW() + INTERVAL '53 DAY')::DATE;
  ```
  (`s` at the end is optional)
- get current age:
  ```sql
  SELECT AGE(NOW(), [starting_date]);
  ```
- constraints:
  - UNIQUE:
    ```sql
    ALTER TABLE [table_name] ADD CONSTRAINT [constraint_name] UNIQUE ([column_name],    [another_column_name], ...);
    ```
    e.g.
    ```sql
    ALTER TABLE person ADD CONSTRAINT unique_email_address UNIQUE (email);
    ```
  - CHECK:
    ```sql
    ALTER TABLE [table_name] ADD CONSTRAINT [constraint_name] CHECK ([condition]);
    ```
    e.g.
    ```sql
     ALTER TABLE person ADD CONSTRAINT CHECK(gender = 'Female' or gender = 'Male');
    ```
- upsert
  : combination of update or insert, could be also referred to as a merge when you are trying to insert row that already exists

  ```sql
  INSERT INTO [table_name]([column_list])
  VALUES([value_list])
  ON CONFLICT [target] [action];
  ```

  - `target` can be one of the following:
    - `[column_name]`
    - `ON CONSTRAINT [constraint_name]` - mostly `UNIQUE` constraint
    - `WHERE [condition]`
  - `action` can be one of the following:
    - `DO NOTHING`
    - `DO UPDATE SET [column_name] = [value], ... WHERE [condition]` - `WHERE` is optional

  e.g.

  ```sql
  INSERT INTO person (name, email, country)
  VALUES('John','email@example.com', 'Germany')
  ON CONFLICT
      ON CONSTRAINT person_name_key
      DO NOTHING;
  ```

  ```sql
  INSERT INTO person (name, email, country)
  VALUES('John','email@example.com', 'Germany')
  ON CONFLICT
      (email)
      DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email, country = EXCLUDED.country;
  ```
