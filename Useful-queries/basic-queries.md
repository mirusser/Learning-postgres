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
    `DROP TABLE <table_name>` 
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
- ignore case sensitivity while filtering a string
    `iLIKE`
    e.g.
    ```
    SELECT country FROM person WHERE country iLIKE '%germ%';
    ```