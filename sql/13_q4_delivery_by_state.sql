-- =====================================================================
-- Q4. Where are deliveries slowest, and does that line up with lower scores?
-- =====================================================================
-- Why it matters
--   Shows logistics where to invest first.
--
-- Approach
--   - Grouped by customer_state, where the order is delivered.
--   - States with fewer than 300 delivered orders are left out, so their
--     averages are not driven by a handful of orders (21 of 27 states kept).
--   - Delivery days = delivered date minus purchase date; late = delivered
--     after the estimated date.
--
-- Part A: delivery days, late rate and average review score by state
-- Part B: the 5 states with the highest late rate (RANK window function)
--
-- Results are saved in results/.
-- =====================================================================

-- Part A: delivery days, late rate and average review score by state
WITH order_scores AS (
    SELECT order_id,
           AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(AVG(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date), 1) AS avg_delivery_days,
       ROUND(100.0 * COUNT(*) FILTER (WHERE o.order_delivered_customer_date::date
                                          > o.order_estimated_delivery_date::date) / COUNT(*), 1) AS late_rate_pct,
       ROUND(AVG(s.review_score), 2) AS avg_review_score
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_scores s ON s.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 300
ORDER BY late_rate_pct DESC;


-- Part B: the 5 states with the highest late rate (RANK window function)
WITH order_scores AS (
    SELECT order_id,
           AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
),
state_performance AS (
    SELECT c.customer_state,
           COUNT(*) AS orders,
           ROUND(AVG(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date), 1) AS avg_delivery_days,
           ROUND(100.0 * COUNT(*) FILTER (WHERE o.order_delivered_customer_date::date
                                              > o.order_estimated_delivery_date::date) / COUNT(*), 1) AS late_rate_pct,
           ROUND(AVG(s.review_score), 2) AS avg_review_score
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    LEFT JOIN order_scores s ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY c.customer_state
    HAVING COUNT(*) >= 300
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY late_rate_pct DESC) AS late_rank
    FROM state_performance
)
SELECT late_rank, customer_state, orders, avg_delivery_days, late_rate_pct, avg_review_score
FROM ranked
WHERE late_rank <= 5
ORDER BY late_rank;
