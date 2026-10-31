-- =====================================================================
-- Q1. What drove Olist's revenue growth from 2017 to 2018?
-- =====================================================================
-- Why it matters
--   Management wants to know whether growth came from more orders,
--   bigger orders, or a few categories.
--
-- Approach
--   - Revenue counts delivered orders only (data check 3) and uses item
--     price, excluding freight (data check 8).
--   - 2016 and Sep to Oct 2018 are incomplete (data check 2), so growth
--     compares Jan to Aug 2017 with Jan to Aug 2018.
--
-- Part A: monthly revenue, orders, average order value and monthly change
--         (DATE_TRUNC, LAG window function)
-- Part B: the 5 categories that added the most revenue
--         (FILTER conditional sums, COALESCE for untranslated names)
--
-- Results are saved in results/.
-- =====================================================================

-- Part A: monthly revenue, orders, average order value and monthly change
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
   


-- Part B: the 5 categories that added the most revenue
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
