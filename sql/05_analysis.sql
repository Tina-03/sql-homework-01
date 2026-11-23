-- 01. Пять продуктов с самой высокой средней ценой продажи
SELECT product_id,
       ROUND(AVG(item_list_price_at_sale), 2) AS avg_sale_price
FROM hw01.order_items
GROUP BY product_id
ORDER BY AVG(item_list_price_at_sale) DESC, product_id
LIMIT 5;

-- 02. Сумма стоимости позиций по брендам
SELECT p.brand,
       SUM(i.item_list_price_at_sale * i.quantity) AS order_value
FROM hw01.products p
JOIN hw01.order_items i ON i.product_id = p.product_id
GROUP BY p.brand
ORDER BY order_value DESC, p.brand;

-- 03. Количество заказов по годам и месяцам
SELECT CAST(EXTRACT(YEAR FROM order_date) AS integer) AS order_year,
       CAST(EXTRACT(MONTH FROM order_date) AS integer) AS order_month,
       COUNT(*) AS order_count
FROM hw01.orders
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY order_year, order_month;

-- 04. Максимальная стандартная себестоимость в каждой линейке
WITH ranked AS (
    SELECT product_id, product_line, standard_cost,
           RANK() OVER (PARTITION BY product_line
                        ORDER BY standard_cost DESC) AS cost_rank
    FROM hw01.products
)
SELECT product_id, product_line, standard_cost
FROM ranked
WHERE cost_rank = 1
ORDER BY product_line, product_id;

-- 05. Количество и полная стоимость заказов по статусам
WITH totals AS (
    SELECT order_id, SUM(item_list_price_at_sale * quantity) AS amount
    FROM hw01.order_items
    GROUP BY order_id
)
SELECT o.order_status, COUNT(*) AS order_count,
       SUM(COALESCE(t.amount, 0)) AS order_value
FROM hw01.orders o
LEFT JOIN totals t ON t.order_id = o.order_id
GROUP BY o.order_status
ORDER BY o.order_status;

-- 06. Клиенты без заказов
SELECT c.customer_id, c.last_name, c.first_name
FROM hw01.customers c
WHERE NOT EXISTS (
    SELECT 1 FROM hw01.orders o WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;

-- 07. Клиенты с минимальной и максимальной оценкой в каждом штате
WITH bounds AS (
    SELECT state, customer_id, last_name, first_name, property_valuation,
           MIN(property_valuation) OVER (PARTITION BY state) AS lo,
           MAX(property_valuation) OVER (PARTITION BY state) AS hi
    FROM hw01.customers
)
SELECT state, CASE WHEN lo = hi THEN 'min/max'
                   WHEN property_valuation = lo THEN 'min'
                   ELSE 'max' END AS extreme,
       property_valuation, last_name, first_name, customer_id
FROM bounds
WHERE property_valuation IN (lo, hi)
ORDER BY state, property_valuation, customer_id;

-- 08. Клиенты, покупавшие товары только одной линейки
WITH purchases AS (
    SELECT o.customer_id, o.order_id, p.product_line
    FROM hw01.orders o
    JOIN hw01.order_items i ON i.order_id = o.order_id
    JOIN hw01.products p ON p.product_id = i.product_id
)
SELECT customer_id, MIN(product_line) AS product_line,
       COUNT(DISTINCT order_id) AS order_count
FROM purchases
GROUP BY customer_id
HAVING COUNT(DISTINCT product_line) = 1
ORDER BY customer_id;

-- 09. Процент отменённых заказов в каждом классе товаров
WITH order_classes AS (
    SELECT DISTINCT i.order_id, p.product_class
    FROM hw01.order_items i
    JOIN hw01.products p ON p.product_id = i.product_id
)
SELECT c.product_class, COUNT(*) AS order_count,
       COUNT(*) FILTER (WHERE o.order_status = 'Cancelled') AS cancelled,
       ROUND(100.0 * COUNT(*) FILTER (WHERE o.order_status = 'Cancelled')
             / COUNT(*), 2) AS cancelled_pct
FROM order_classes c
JOIN hw01.orders o ON o.order_id = c.order_id
GROUP BY c.product_class
ORDER BY c.product_class;

-- 10. Сегменты клиентов по числу заказов
WITH counts AS (
    SELECT c.customer_id, COUNT(o.order_id) AS n
    FROM hw01.customers c
    LEFT JOIN hw01.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
), segments AS (
    SELECT CASE WHEN n > 10 THEN 'High'
                WHEN n >= 5 THEN 'Medium'
                ELSE 'Low' END AS segment
    FROM counts
)
SELECT segment, COUNT(*) AS customer_count
FROM segments
GROUP BY segment
ORDER BY CASE segment WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;

-- 11. Максимальный интервал между последовательными заказами, дни
WITH timeline AS (
    SELECT customer_id, order_date,
           LAG(order_date) OVER (PARTITION BY customer_id
                                 ORDER BY order_date, order_id) AS previous_date
    FROM hw01.orders
), gaps AS (
    SELECT customer_id,
           ROUND(CAST(MAX(EXTRACT(EPOCH FROM (order_date - previous_date)))
                      AS numeric) / 86400, 2) AS max_gap_days
    FROM timeline
    WHERE previous_date IS NOT NULL
    GROUP BY customer_id
)
SELECT c.customer_id, c.first_name, c.last_name,
       c.job_title, g.max_gap_days
FROM gaps g
JOIN hw01.customers c ON c.customer_id = g.customer_id
ORDER BY g.max_gap_days DESC, c.customer_id;
