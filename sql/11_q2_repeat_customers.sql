-- =====================================================================
-- Q2. How many customers come back, and how fast?
-- =====================================================================
-- Why it matters
--   A business that relies only on first-time buyers spends heavily on
--   acquisition. The repeat rate shows how much room retention has.
--
-- Approach
--   - Customers are counted with customer_unique_id, because Olist creates
--     a new customer_id for every order (data check 9).
--   - Canceled and unavailable orders are left out.
--
-- Part A: repeat purchase rate
-- Part B: days from first to second order, and the median
--         (ROW_NUMBER window function, PERCENTILE_CONT)
--
-- Results are saved in results/.
-- =====================================================================

-- Part A: repeat purchase rate
WITH customer_orders AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS orders
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS customers,
       COUNT(*) FILTER (WHERE orders >= 2) AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;


-- Part B: days from first to second order, and the median
WITH ranked AS (
    SELECT c.customer_unique_id,
           o.order_purchase_timestamp,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                              ORDER BY o.order_purchase_timestamp, o.order_id) AS order_number
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
first_two AS (
    SELECT customer_unique_id,
           MAX(order_purchase_timestamp) FILTER (WHERE order_number = 1)::date AS first_order,
           MAX(order_purchase_timestamp) FILTER (WHERE order_number = 2)::date AS second_order
    FROM ranked
    WHERE order_number <= 2
    GROUP BY customer_unique_id
    HAVING COUNT(*) = 2
)
SELECT COUNT(*) AS repeat_customers,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY second_order - first_order) AS median_days,
       ROUND(AVG(second_order - first_order), 1) AS avg_days,
       COUNT(*) FILTER (WHERE second_order = first_order) AS same_day,
       ROUND(100.0 * COUNT(*) FILTER (WHERE second_order = first_order) / COUNT(*), 1) AS same_day_pct
FROM first_two;
