# Foreign keys & joins

- foreign key:

  ```
  CONSTRAINT <foreing_key_name>
  FOREIGN KEY(<foreign_key_column>)
  REFERENCES <parent_table>(<parent_key_columns>)
  [ON DELETE <delete_action>]
  [ON UPDATE <update_action>]
  ```

  e.g.

  ```
  CREATE TABLE customers(
  customer_id INT GENERATED ALWAYS AS IDENTITY,
  customer_name VARCHAR(255) NOT NULL,
  PRIMARY KEY(customer_id)
  );

  CREATE TABLE contacts(
      contact_id INT GENERATED ALWAYS AS IDENTITY,
      customer_id INT,
      contact_name VARCHAR(255) NOT NULL,
      phone VARCHAR(15),
      email VARCHAR(100),
      PRIMARY KEY(contact_id),
      CONSTRAINT fk_customer
        FOREIGN KEY(customer_id)
  	    REFERENCES customers(customer_id)
        ON DELETE SET NULL
  );
  ```

  ```
  CREATE TABLE car(
      id BIGSERIAL NOT NULL PRIMARY KEY,
      make VARCHAR(100) NOT NULL,
      model VARCHAR(100) NOT NULL,
      price NUMERIC(19,2) NOT NULL,
  );

  CREATE TABLE person(
      id BIGSERIAL NOT NULL PRIMARY KEY,
      first_name VARCHAR(255) NOT NULL,
      last_name VARCHAR(255) NOT NULL,
      gender VARCHAR(20) NOT NULL,
      email VARCHAR(100),
      date_of_birth DATE NOT NULL,
      country_of_birth VARCHAR(50) NOT NULL,
      car_id BIGINT REFERENCES car (id),
      UNIQUE(car_id)
  );
  ```
