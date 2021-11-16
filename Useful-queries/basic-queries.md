# Basic queries

- Create database:
  `CREATE DATABASE <database_name>;`
- Drop\delete database:
  `DROP DATABASE <database_name>;` 
  e.g.
    ```
    DROP DATABASE my_database;
    ```
- Create table:
    `CREATE TABLE <table_name> (<column_name> <data_type>, ...);` 
    e.g. 
    ```
    CREATE TABLE my_table (id INT, name VARCHAR(255));
    ```
- Create table with constraints:
    `CREATE TABLE <table_name> (<column_name> <data_type> <constraints>, ...)` 
    e.g. 
    ```
    CREATE TABLE person (
        id BIGSERIAL NOT NULL PRIMARY KEY,
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        gender VARCHAR(5) NOT NULL,
        date_of_birth DATE NOT NULL
    );  
    ```
- drop/delete table:
    `DROP TABLE <table_name>;` 
    e.g. 
    ```
    DROP TABLE person;
    ```
- insert/add records into table:
    ```
    INSERT INTO <table_name> (
        <column_name>,
        <column_name>,
        ...) 
    VALUES (
        <value>,
        <value>,
        ...);
    ```
    e.g.
    ```
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
    `SELECT * FROM  <table_name>;`
- show certain number of rows from a table:
    `SELECT * FROM <table_name> LIMIT <number_of_rows>;`
    e.g.
    ```
    SELECT * FROM person LIMIT 10;
    SELECT * FROM person FETCH FIRST 10 ROWS ONLY;
    ```
- show content of a table and skip certain number of rows:
    `SELECT * FROM <table_name> OFFSET <number_of_rows>;`
    e.g.
    ```
    SELECT * FROM person OFFSET 5;
    ```
- change column type:
    ` ALTER TABLE <table_name> ALTER COLUMN <column_name> TYPE <data_type>;`
    or 
    ```
    ALTER TABLE <table_name> ALTER COLUMN <column_name> TYPE <data_type> USING <column_name>::<data_type>;
    ```
    e.g.
    ```
    ALTER TABLE person ALTER COLUMN gender TYPE VARCHAR(10);
    ```
- delete/remove records:
    `DELETE FROM <table_name> WHERE <condition>;`
    e.g.
    ```
    DELETE FROM person WHERE Id = 12;
    ```
- update records:
    ```
    UPDATE <table_name> 
    SET 
        <column_name> = <value>,
        <another_column_name> = <another_value>, 
        ... 
    WHERE <condition>;
    ```
    e.g.
    ```
    UPDATE person 
    SET 
        email = 'example@example.com`
    WHERE Id = 12;
    ```

- ignore case sensitivity while filtering a string
    `iLIKE`
    e.g.
    ```
    SELECT country FROM person WHERE country iLIKE '%germ%';
    ```
- coalesce - return first non-null value
    `COALESCE(<argument_1>, <argument_2>, ...)`
    e.g.
    ```
    SELECT COALESCE(country, 'Unknown') FROM person;
    ```
    - coalesce with nullif e.g.
    ```
    select coalesce(10/nullif(0,0), 0);
    ```
- get current timestamp (full date):
    `SELECT NOW();`
- get current date:
    `SELECT NOW()::DATE;`
- get current time:
    `SELECT NOW()::TIME;`
- adding and subtracting with dates e.g.
    ```
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
    `SELECT AGE(NOW(), <starting_date>);`
- constraints:
    - UNIQUE:
    `ALTER TABLE <table_name> ADD CONSTRAINT <constraint_name> UNIQUE (<column_name>, <another_column_name>, ...);`
    e.g.
        ```
        ALTER TABLE person ADD CONSTRAINT unique_email_address UNIQUE (email);
        ```
    - CHECK: 
    `ALTER TABLE <table_name> ADD CONSTRAINT <constraint_name> CHECK (<condition>);`
    e.g.
        ```
        ALTER TABLE person ADD CONSTRAINT CHECK(gender = 'Female' or gender = 'Male');
        ```
- upsert 
    : combination of update or insert, could be also referred to as a merge when you are trying to insert row that already exists
    ```
    INSERT INTO <table_name>(<column_list>) 
    VALUES(<value_list>)
    ON CONFLICT <target> <action>;
    ```
    - `target` can be one of the following:
        - `<column_name>`
        - `ON CONSTRAINT <constraint_name>` - mostly `UNIQUE` constraint
        - `WHERE <condition>`
    - `action` can be one of the following:
        - `DO NOTHING`
        - `DO UPDATE SET <column_name> = <value>, ... WHERE <condition>` - `WHERE` is optional

    e.g.
    ```
    INSERT INTO person (name, email, country)
    VALUES('John','email@example.com', 'Germany') 
    ON CONFLICT 
        ON CONSTRAINT person_name_key 
        DO NOTHING;
    ```
    ```
    INSERT INTO person (name, email, country)
    VALUES('John','email@example.com', 'Germany') 
    ON CONFLICT 
        (email) 
        DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email, country = EXCLUDED.country;
    ```
