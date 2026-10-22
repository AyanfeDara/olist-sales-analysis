-- =====================================================================
-- Q2. How many customers come back, and how fast?
-- =====================================================================
-- WHY IT MATTERS
--   A business that relies only on first-time buyers spends heavily on
--   acquisition. The repeat rate shows how much room retention has.
--
-- DECISIONS TO MAKE FIRST
--   - Use customer_unique_id, not customer_id (check 9 shows why).
--   - Count only orders that were not canceled or unavailable.
--
-- PART A: repeat purchase rate
--   Output columns: customers, repeat_customers, repeat_rate_pct
--   Hint: count orders per customer_unique_id in a CTE, then count how many have 2 or more.
--
-- PART B: days between first and second order for repeat customers
--   Output columns: customer_unique_id, first_order, second_order, days_between
--   Then summarise: median days (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ...)).
--   Hint: ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp).
--
-- PART C (stretch): monthly cohort retention
--   Group customers by the month of their first order, then count how many
--   ordered again in each later month. This is a classic interview question.
--
-- SELF-CHECK
--   The total in Part A should be close to the unique customer count in check 9.
-- =====================================================================

-- Part A: write your query below.
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


-- Part B: write your query below.
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


-- Part C: write your query below.

