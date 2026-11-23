-- Первичные и внешние ключи, включая целевой столбец каждой ссылки.
SELECT tc.table_name, tc.constraint_type, k.column_name,
       dest.table_name AS parent_table, dest.column_name AS parent_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage k
  ON (k.constraint_catalog, k.constraint_schema, k.constraint_name, k.table_name)
   = (tc.constraint_catalog, tc.constraint_schema, tc.constraint_name, tc.table_name)
LEFT JOIN information_schema.referential_constraints rc
  ON (rc.constraint_catalog, rc.constraint_schema, rc.constraint_name)
   = (tc.constraint_catalog, tc.constraint_schema, tc.constraint_name)
LEFT JOIN information_schema.key_column_usage dest
  ON (dest.constraint_catalog, dest.constraint_schema, dest.constraint_name)
   = (rc.unique_constraint_catalog, rc.unique_constraint_schema,
      rc.unique_constraint_name)
 AND dest.ordinal_position = k.position_in_unique_constraint
WHERE tc.table_schema = 'hw01'
  AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY tc.table_name, tc.constraint_type, k.column_name;

SELECT 'customers' AS tbl, COUNT(*) AS final_rows FROM hw01.customers
UNION ALL SELECT 'products', COUNT(*) FROM hw01.products
UNION ALL SELECT 'orders', COUNT(*) FROM hw01.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM hw01.order_items
UNION ALL SELECT 'regions', COUNT(*) FROM hw01.regions
ORDER BY tbl;

-- Разность в обе стороны должна быть пустой: восстановление без потерь.
SELECT 'source_minus_view' AS direction, COUNT(*) AS differences
FROM (SELECT * FROM hw01_raw.customers
      EXCEPT SELECT * FROM hw01.customers_with_country) a
UNION ALL
SELECT 'view_minus_source', COUNT(*)
FROM (SELECT * FROM hw01.customers_with_country
      EXCEPT SELECT * FROM hw01_raw.customers) b;
