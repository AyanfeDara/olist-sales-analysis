-- =====================================================================
-- Q1. What drove Olist's revenue growth from 2017 to 2018?
-- =====================================================================
-- WHY IT MATTERS
--   Management wants to know whether growth came from more orders,
--   bigger orders, or a few categories.
--
-- DECISIONS TO MAKE FIRST (write them in the README under "Method")
--   - Which order statuses count as revenue? (see check 3)
--   - Revenue = item price, or price + freight? (see check 8)
--   - Which months are complete enough to compare? (see check 2)
--     A fair comparison is Jan to Aug 2017 against Jan to Aug 2018.
--
-- PART A: monthly revenue, order count and average order value
--   Output columns: month, orders, revenue, avg_order_value, revenue_mom_change_pct
--   Hints: DATE_TRUNC('month', ...), a CTE per step,
--          LAG(revenue) OVER (ORDER BY month) for month-on-month change.
--
-- PART B: top 5 categories by revenue growth (2018 Jan-Aug against 2017 Jan-Aug)
--   Output columns: category_english, revenue_2017, revenue_2018, growth_abs, growth_pct
--   Hints: join products and category_translation; COALESCE the English name
--          for the untranslated categories (check 7); conditional sums with
--          SUM(...) FILTER (WHERE ...).
--
-- SELF-CHECK
--   Sum your monthly revenue and compare it with the total from check 8.
--   If yours is higher, a join has duplicated rows.
--
-- EXPORT (run in psql after the query works; paste your query inside the brackets,
--   on ONE line, without the closing semicolon). The path is relative to
--   data/raw, the folder you moved into with \cd during setup.
--   \copy ( <your query> ) TO '../../results/q1a_monthly_revenue.csv' WITH (FORMAT csv, HEADER true)
--   Easier alternative: in pgAdmin's Query Tool, run the query and use
--   "Save results to file" (the download icon above the results grid).
-- =====================================================================

-- Part A: write your query below.
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(i.price) AS revenue
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1
)
SELECT month,
       orders,
       revenue,
       ROUND(revenue / orders, 2) AS avg_order_value,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS revenue_mom_change_pct
FROM monthly
ORDER BY month;
   


-- Part B: write your query below.
WITH category_revenue AS (
    SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
           COALESCE(SUM(i.price) FILTER (WHERE o.order_purchase_timestamp >= '2017-01-01'
                                           AND o.order_purchase_timestamp <  '2017-09-01'), 0) AS revenue_2017,
           COALESCE(SUM(i.price) FILTER (WHERE o.order_purchase_timestamp >= '2018-01-01'
                                           AND o.order_purchase_timestamp <  '2018-09-01'), 0) AS revenue_2018
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    JOIN products p ON p.product_id = i.product_id
    LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT category,
       revenue_2017,
       revenue_2018,
       revenue_2018 - revenue_2017 AS growth_abs,
       ROUND(100.0 * (revenue_2018 - revenue_2017) / NULLIF(revenue_2017, 0), 1) AS growth_pct
FROM category_revenue
ORDER BY growth_abs DESC
LIMIT 5;

