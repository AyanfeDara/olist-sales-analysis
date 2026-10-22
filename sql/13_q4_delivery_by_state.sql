-- =====================================================================
-- Q4. Where are deliveries slowest, and does that line up with lower scores?
-- =====================================================================
-- WHY IT MATTERS
--   Shows logistics where to invest first.
--
-- DECISIONS TO MAKE FIRST
--   - Group by customer_state (where the order is delivered).
--   - Leave out states with very few orders (for example fewer than 300),
--     or their averages will be noisy. Say what cut-off you used.
--
-- PART A: delivery performance by state
--   Output columns: customer_state, orders, avg_delivery_days, late_rate_pct, avg_review_score
--   delivery days = delivered date minus purchase date (cast both to ::date)
--   late = delivered date after the estimated delivery date
--   Hints: HAVING COUNT(*) >= 300; ROUND(..., 1) for readable numbers.
--
-- PART B: rank states
--   Add RANK() OVER (ORDER BY late_rate_pct DESC) and keep the worst 5.
--
-- PART C (stretch): state-to-state lanes
--   Join sellers to get seller_state, then find the seller_state to
--   customer_state pairs with the highest late rate (minimum 200 orders).
-- =====================================================================

-- Part A: write your query below.
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


-- Part B: write your query below.
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


-- Part C: write your query below.

