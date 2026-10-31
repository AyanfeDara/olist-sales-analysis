-- =====================================================================
-- Q3. Do late deliveries go with bad reviews?
-- =====================================================================
-- Why it matters
--   If lateness drives low scores, fixing logistics protects ratings,
--   which drive future sales on the marketplace.
--
-- Approach
--   - Delivered orders with a delivery date only (data check 4).
--   - Delay in days = delivered date minus estimated date
--     (negative = early, positive = late).
--   - Orders with several reviews (data check 6) are averaged per order
--     first, so they are not counted twice.
--   - This shows association, not proof of cause: product quality or the
--     seller could also explain low scores.
--
-- Part A: average review score and share of 1-star reviews by delay
-- Part B: share of all 1-star reviews that come from late orders
--
-- Results are saved in results/.
-- =====================================================================

-- Part A: average review score and share of 1-star reviews by delay
WITH order_scores AS (
    SELECT order_id,
           AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
),
delivered AS (
    SELECT o.order_id,
           o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date AS delay_days
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),
bucketed AS (
    SELECT d.order_id,
           s.review_score,
           CASE
               WHEN d.delay_days < -7 THEN 1
               WHEN d.delay_days < 0  THEN 2
               WHEN d.delay_days = 0  THEN 3
               WHEN d.delay_days <= 3 THEN 4
               WHEN d.delay_days <= 7 THEN 5
               ELSE 6
           END AS sort_key
    FROM delivered d
    JOIN order_scores s ON s.order_id = d.order_id
)
SELECT sort_key,
       CASE sort_key
           WHEN 1 THEN 'More than 7 days early'
           WHEN 2 THEN '1-7 days early'
           WHEN 3 THEN 'On the estimated day'
           WHEN 4 THEN '1-3 days late'
           WHEN 5 THEN '4-7 days late'
           ELSE 'More than 7 days late'
       END AS delay_bucket,
       COUNT(*) AS orders,
       ROUND(AVG(review_score), 2) AS avg_review_score,
       ROUND(100.0 * COUNT(*) FILTER (WHERE review_score = 1) / COUNT(*), 1) AS pct_1_star
FROM bucketed
GROUP BY sort_key
ORDER BY sort_key;


-- Part B: share of all 1-star reviews that come from late orders
WITH order_scores AS (
    SELECT order_id,
           AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
),
delivered AS (
    SELECT o.order_id,
           o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date AS delay_days
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT COUNT(*) FILTER (WHERE s.review_score = 1) AS one_star_reviews,
       COUNT(*) FILTER (WHERE s.review_score = 1 AND d.delay_days > 0) AS one_star_from_late,
       ROUND(100.0 * COUNT(*) FILTER (WHERE s.review_score = 1 AND d.delay_days > 0)
                   / COUNT(*) FILTER (WHERE s.review_score = 1), 1) AS pct_from_late,
       ROUND(100.0 * COUNT(*) FILTER (WHERE d.delay_days > 0) / COUNT(*), 1) AS pct_of_orders_late
FROM delivered d
JOIN order_scores s ON s.order_id = d.order_id;
