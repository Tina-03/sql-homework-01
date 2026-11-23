-- В новой учебной базе выполнить целиком, затем загрузить четыре CSV.
BEGIN;
CREATE SCHEMA hw01_raw;

CREATE TABLE hw01_raw.customers (
    customer_id integer, first_name text, last_name text, gender text,
    dob date, job_title text, job_industry_category text, wealth_segment text,
    deceased_indicator boolean, owns_car boolean, address text,
    postcode text, state text, country text, property_valuation numeric
);

CREATE TABLE hw01_raw.products (
    product_id integer, brand text, product_line text, product_class text,
    product_size text, list_price numeric, standard_cost numeric
);

CREATE TABLE hw01_raw.orders (
    order_id integer, customer_id integer, order_date timestamp,
    online_order boolean, order_status text
);

CREATE TABLE hw01_raw.order_items (
    order_item_id integer, order_id integer, product_id integer,
    quantity integer, item_list_price_at_sale numeric,
    item_standard_cost_at_sale numeric
);
COMMIT;
