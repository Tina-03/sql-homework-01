-- Запустить целиком после импорта. При ошибке выполнить ROLLBACK.
BEGIN;
CREATE SCHEMA hw01;

CREATE TABLE hw01.regions (
    state text NOT NULL, country text NOT NULL
);

CREATE TABLE hw01.customers (
    customer_id integer NOT NULL, first_name text NOT NULL,
    last_name text NOT NULL, gender text NOT NULL, dob date NOT NULL,
    job_title text NOT NULL, job_industry_category text NOT NULL,
    wealth_segment text NOT NULL, deceased_indicator boolean NOT NULL,
    owns_car boolean NOT NULL, address text NOT NULL, postcode text NOT NULL,
    state text NOT NULL, property_valuation numeric(12,2) NOT NULL,
    CHECK (property_valuation >= 0)
);

CREATE TABLE hw01.products (
    product_id integer NOT NULL, brand text NOT NULL,
    product_line text NOT NULL, product_class text NOT NULL,
    product_size text NOT NULL, list_price numeric(12,2) NOT NULL,
    standard_cost numeric(12,2) NOT NULL,
    CHECK (list_price >= 0), CHECK (standard_cost >= 0)
);

CREATE TABLE hw01.orders (
    order_id integer NOT NULL, customer_id integer NOT NULL,
    order_date timestamp NOT NULL, online_order boolean NOT NULL,
    order_status text NOT NULL
);

CREATE TABLE hw01.order_items (
    order_item_id integer NOT NULL, order_id integer NOT NULL,
    product_id integer NOT NULL, quantity integer NOT NULL,
    item_list_price_at_sale numeric(12,2) NOT NULL,
    item_standard_cost_at_sale numeric(12,2) NOT NULL,
    CHECK (quantity > 0), CHECK (item_list_price_at_sale >= 0),
    CHECK (item_standard_cost_at_sale >= 0)
);

-- SELECT DISTINCT удаляет только полные повторы. Конфликты ID
-- остановят транзакцию при добавлении PK или FK.
INSERT INTO hw01.regions
SELECT DISTINCT state, country FROM hw01_raw.customers;

INSERT INTO hw01.customers
SELECT DISTINCT customer_id, first_name, last_name, gender, dob, job_title,
       job_industry_category, wealth_segment, deceased_indicator,
       owns_car, address, postcode, state, property_valuation
FROM hw01_raw.customers;

INSERT INTO hw01.products
SELECT DISTINCT product_id, brand, product_line, product_class,
       product_size, list_price, standard_cost
FROM hw01_raw.products;

INSERT INTO hw01.orders
SELECT DISTINCT order_id, customer_id, order_date, online_order, order_status
FROM hw01_raw.orders;

INSERT INTO hw01.order_items
SELECT DISTINCT order_item_id, order_id, product_id, quantity,
       item_list_price_at_sale, item_standard_cost_at_sale
FROM hw01_raw.order_items;

ALTER TABLE hw01.regions ADD PRIMARY KEY (state);
ALTER TABLE hw01.customers ADD PRIMARY KEY (customer_id);
ALTER TABLE hw01.products ADD PRIMARY KEY (product_id);
ALTER TABLE hw01.orders ADD PRIMARY KEY (order_id);
ALTER TABLE hw01.order_items ADD PRIMARY KEY (order_item_id);

ALTER TABLE hw01.customers ADD FOREIGN KEY (state)
    REFERENCES hw01.regions (state);
ALTER TABLE hw01.orders ADD FOREIGN KEY (customer_id)
    REFERENCES hw01.customers (customer_id);
ALTER TABLE hw01.order_items ADD FOREIGN KEY (order_id)
    REFERENCES hw01.orders (order_id);
ALTER TABLE hw01.order_items ADD FOREIGN KEY (product_id)
    REFERENCES hw01.products (product_id);

-- Представление восстанавливает все 15 исходных полей клиента.
CREATE VIEW hw01.customers_with_country AS
SELECT c.customer_id, c.first_name, c.last_name, c.gender, c.dob,
       c.job_title, c.job_industry_category, c.wealth_segment,
       c.deceased_indicator, c.owns_car, c.address, c.postcode,
       c.state, r.country, c.property_valuation
FROM hw01.customers c
JOIN hw01.regions r ON r.state = c.state;
COMMIT;
