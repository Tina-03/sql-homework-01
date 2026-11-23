-- Количество строк, уникальных ID, пустых ID и лишних непустых ID.
WITH ids AS (
    SELECT 'customers' AS tbl, customer_id AS id FROM hw01_raw.customers
    UNION ALL SELECT 'products', product_id FROM hw01_raw.products
    UNION ALL SELECT 'orders', order_id FROM hw01_raw.orders
    UNION ALL SELECT 'order_items', order_item_id FROM hw01_raw.order_items
)
SELECT tbl, COUNT(*) AS source_rows, COUNT(DISTINCT id) AS unique_ids,
       COUNT(*) - COUNT(id) AS null_ids,
       COUNT(id) - COUNT(DISTINCT id) AS duplicate_rows
FROM ids
GROUP BY tbl
ORDER BY tbl;

-- Ссылки без родительской записи, включая пустые значения FK.
SELECT 'orders.customer_id' AS fk, COUNT(*) AS orphan_rows
FROM hw01_raw.orders o
WHERE NOT EXISTS (SELECT 1 FROM hw01_raw.customers c
                  WHERE c.customer_id = o.customer_id)
UNION ALL
SELECT 'order_items.order_id', COUNT(*) FROM hw01_raw.order_items i
WHERE NOT EXISTS (SELECT 1 FROM hw01_raw.orders o
                  WHERE o.order_id = i.order_id)
UNION ALL
SELECT 'order_items.product_id', COUNT(*) FROM hw01_raw.order_items i
WHERE NOT EXISTS (SELECT 1 FROM hw01_raw.products p
                  WHERE p.product_id = i.product_id);

-- Проверки зависимостей. Сколько значений слева имеют несколько значений справа?
SELECT 'state -> country' AS dependency, COUNT(*) AS exceptions
FROM (SELECT state FROM hw01_raw.customers GROUP BY state
      HAVING COUNT(DISTINCT country) > 1) s
UNION ALL
SELECT 'postcode -> state', COUNT(*)
FROM (SELECT postcode FROM hw01_raw.customers GROUP BY postcode
      HAVING COUNT(DISTINCT state) > 1) z
UNION ALL
SELECT 'job_title -> job_industry_category', COUNT(*)
FROM (SELECT job_title FROM hw01_raw.customers GROUP BY job_title
      HAVING COUNT(DISTINCT job_industry_category) > 1) j;
