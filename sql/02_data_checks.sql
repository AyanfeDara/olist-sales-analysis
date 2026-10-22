-- =====================================================================
-- 02_data_checks.sql
-- Run after loading. Each check prints a small result.
-- Write down what you find in notes/data_quality.md: these quirks
-- decide how you write the analysis queries, and interviewers ask about them.
-- =====================================================================

-- 1. Row counts. Expected: customers 99,441 | geolocation 1,000,163 |
--    sellers 3,095 | products 32,951 | orders 99,441 | order_items 112,650 |
--    order_payments 103,886 | order_reviews 99,224 | category_translation 71
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'geolocation',          COUNT(*) FROM geolocation
UNION ALL SELECT 'sellers',              COUNT(*) FROM sellers
UNION ALL SELECT 'products',             COUNT(*) FROM products
UNION ALL SELECT 'orders',               COUNT(*) FROM orders
UNION ALL SELECT 'order_items',          COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments',       COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',        COUNT(*) FROM order_reviews
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation
ORDER BY table_name;

-- 2. Date range of purchases. Are the first and last months complete?
--    Partial months distort monthly trends.
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY 1;

-- 3. Order status mix. Which statuses should count as revenue?
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 4. Delivered orders missing a delivery date. Exclude them from delay analysis.
SELECT COUNT(*) AS delivered_without_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 5. Orders with no items, and orders with no payment.
SELECT
    (SELECT COUNT(*) FROM orders o
      WHERE NOT EXISTS (SELECT 1 FROM order_items i WHERE i.order_id = o.order_id))    AS orders_without_items,
    (SELECT COUNT(*) FROM orders o
      WHERE NOT EXISTS (SELECT 1 FROM order_payments p WHERE p.order_id = o.order_id)) AS orders_without_payment;

-- 6. Orders with more than one review. Averaging scores per order needs care.
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (SELECT order_id FROM order_reviews GROUP BY order_id HAVING COUNT(*) > 1) t;

-- 7. Product categories with no English translation, and products with no category.
SELECT p.product_category_name, COUNT(*) AS products
FROM products p
LEFT JOIN category_translation t USING (product_category_name)
WHERE t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY products DESC;

-- 8. Item revenue against payments. Payments include freight and instalment
--    interest, so the two totals differ. Decide which one "revenue" means.
SELECT
    (SELECT SUM(price)                 FROM order_items)    AS item_price_total,
    (SELECT SUM(price + freight_value) FROM order_items)    AS price_plus_freight_total,
    (SELECT SUM(payment_value)         FROM order_payments) AS payments_total;

-- 9. Customers: accounts against real people. customer_id is per order;
--    customer_unique_id is the person. Use the second for repeat purchases.
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;
