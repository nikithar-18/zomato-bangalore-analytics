-- ============================================================
-- Phase 2: 20 SQL Queries — Zomato Bangalore Analytics
-- Run against zomato_bangalore.db (restaurants, orders, merged_orders view)
-- ============================================================

-- ============================================================
-- THEME 1: Rating-to-Cost Ratio (Q1-3)
-- ============================================================

-- Q1: Raw rating-to-cost ratio (demonstrates why this metric is misleading)
SELECT
    name AS restaurant_name,
    rate_numeric,
    approx_cost_for_two,
    ROUND(rate_numeric / approx_cost_for_two, 4) AS rating_to_cost_ratio
FROM restaurants
WHERE rate_numeric IS NOT NULL
  AND approx_cost_for_two IS NOT NULL
  AND approx_cost_for_two > 0
ORDER BY rating_to_cost_ratio DESC;

-- Q2: Top 3 rated restaurants per cost tier (fixes Q1's bias)
SELECT * FROM (
    SELECT
        name AS restaurant_name,
        rate_numeric,
        approx_cost_for_two,
        CASE
            WHEN approx_cost_for_two < 300 THEN 'Budget'
            WHEN approx_cost_for_two <= 700 THEN 'Mid-range'
            ELSE 'Premium'
        END AS cost_tier,
        RANK() OVER (
            PARTITION BY cost_tier
            ORDER BY rate_numeric DESC
        ) AS rating_rank
    FROM restaurants
    WHERE rate_numeric IS NOT NULL
)
WHERE rating_rank <= 3
ORDER BY cost_tier, rating_rank;

-- Q3: Average rating per cost tier
SELECT
    CASE
        WHEN approx_cost_for_two < 300 THEN 'Budget'
        WHEN approx_cost_for_two <= 700 THEN 'Mid-range'
        ELSE 'Premium'
    END AS cost_tier,
    ROUND(AVG(rate_numeric), 2) AS average_rating,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE rate_numeric IS NOT NULL
  AND approx_cost_for_two IS NOT NULL
  AND approx_cost_for_two > 0
GROUP BY cost_tier;

-- ============================================================
-- THEME 2: Underserved Localities (Q4-6)
-- ============================================================

-- Q4: Restaurant count per locality (raw supply)
SELECT
    location,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE location IS NOT NULL
GROUP BY location
ORDER BY restaurant_count ASC;

-- Q5: Orders per restaurant per locality
-- NOTE: excluded from final findings — orders were randomly assigned,
-- independent of locality, so this metric reflects noise, not real demand.
SELECT
    location,
    COUNT(DISTINCT restaurant_id) AS restaurant_count,
    COUNT(*) AS total_orders,
    ROUND(CAST(COUNT(*) AS REAL) / COUNT(DISTINCT restaurant_id), 2) AS orders_per_restaurant
FROM merged_orders
WHERE location IS NOT NULL
GROUP BY location
ORDER BY orders_per_restaurant DESC;

-- Q6: Underserved localities — count + quality, with minimum sample size
SELECT
    location,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rate_numeric), 2) AS average_rating
FROM restaurants
WHERE location IS NOT NULL
  AND rate_numeric IS NOT NULL
GROUP BY location
HAVING COUNT(*) >= 5 AND COUNT(*) < 20
ORDER BY average_rating DESC;

-- ============================================================
-- THEME 3: Delivery Time by Area (Q7-10)
-- ============================================================

-- Q7: Average delivery time per locality (unfiltered — shows noise from small samples)
SELECT
    location,
    ROUND(AVG(delivery_time_mins), 2) AS average_delivery_time,
    COUNT(*) AS order_count
FROM merged_orders
WHERE location IS NOT NULL
GROUP BY location
ORDER BY average_delivery_time DESC;

-- Q8: Same query, filtered to reliable sample sizes
SELECT
    location,
    ROUND(AVG(delivery_time_mins), 2) AS average_delivery_time,
    COUNT(*) AS order_count
FROM merged_orders
WHERE location IS NOT NULL
GROUP BY location
HAVING COUNT(*) >= 30
ORDER BY average_delivery_time DESC;

-- Q9: Delivery time vs order size (items_count)
SELECT
    CASE
        WHEN items_count <= 2 THEN '1-2 items'
        WHEN items_count <= 4 THEN '3-4 items'
        ELSE '5-6 items'
    END AS item_bucket,
    ROUND(AVG(delivery_time_mins), 2) AS average_delivery_time,
    COUNT(*) AS order_count
FROM merged_orders
WHERE items_count IS NOT NULL
  AND delivery_time_mins IS NOT NULL
GROUP BY item_bucket
ORDER BY
    CASE item_bucket
        WHEN '1-2 items' THEN 1
        WHEN '3-4 items' THEN 2
        WHEN '5-6 items' THEN 3
    END;

-- Q10: Order value vs cost tier (real designed-in relationship)
SELECT
    CASE
        WHEN approx_cost_for_two < 300 THEN 'Budget'
        WHEN approx_cost_for_two <= 700 THEN 'Mid-range'
        ELSE 'Premium'
    END AS cost_tier,
    ROUND(AVG(order_value), 2) AS average_order_value,
    COUNT(*) AS order_count
FROM merged_orders
WHERE approx_cost_for_two IS NOT NULL
  AND order_value IS NOT NULL
  AND approx_cost_for_two > 0
GROUP BY cost_tier
ORDER BY
    CASE cost_tier
        WHEN 'Budget' THEN 1
        WHEN 'Mid-range' THEN 2
        WHEN 'Premium' THEN 3
    END;

-- ============================================================
-- THEME 4: Restaurant Churn & Peak Hours (Q11-15)
-- ============================================================

-- Q11: Orders per customer
SELECT
    customer_id,
    customer_name,
    COUNT(*) AS order_count
FROM merged_orders
WHERE customer_id IS NOT NULL
GROUP BY customer_id, customer_name
ORDER BY order_count DESC;

-- Q12: One-time vs repeat customer split
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS num_customers
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM merged_orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
GROUP BY customer_type;

-- Q13: Orders by hour of day (verifies peak-hour generation logic)
SELECT
    CAST(strftime('%H', order_time) AS INTEGER) AS order_hour,
    COUNT(*) AS order_count
FROM merged_orders
WHERE order_time IS NOT NULL
GROUP BY order_hour
ORDER BY order_hour;

-- Q14: Weekday vs weekend average order value
SELECT
    CASE
        WHEN CAST(strftime('%w', order_date) AS INTEGER) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    ROUND(AVG(order_value), 2) AS average_order_value,
    COUNT(*) AS order_count
FROM merged_orders
WHERE order_date IS NOT NULL
  AND order_value IS NOT NULL
GROUP BY day_type
ORDER BY
    CASE day_type
        WHEN 'Weekday' THEN 1
        WHEN 'Weekend' THEN 2
    END;

-- Q15: Peak-hour timing by customer type (repeat vs one-time)
WITH customer_orders AS (
    SELECT
        customer_id,
        CASE
            WHEN COUNT(*) = 1 THEN 'One-time customer'
            ELSE 'Repeat customer'
        END AS customer_type
    FROM merged_orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    co.customer_type,
    CASE
        WHEN CAST(strftime('%H', mo.order_time) AS INTEGER) IN (12, 13) THEN 'Lunch'
        WHEN CAST(strftime('%H', mo.order_time) AS INTEGER) IN (19, 20, 21) THEN 'Dinner'
        ELSE 'Other'
    END AS time_bucket,
    COUNT(*) AS order_count
FROM merged_orders AS mo
JOIN customer_orders AS co ON mo.customer_id = co.customer_id
WHERE mo.order_time IS NOT NULL
GROUP BY co.customer_type, time_bucket
ORDER BY
    CASE co.customer_type WHEN 'One-time customer' THEN 1 WHEN 'Repeat customer' THEN 2 END,
    CASE time_bucket WHEN 'Lunch' THEN 1 WHEN 'Dinner' THEN 2 WHEN 'Other' THEN 3 END;

-- ============================================================
-- THEME 5: Cross-Cutting Insights — Real Kaggle Data (Q16-20)
-- ============================================================

-- Q16: Top cuisine combinations by count and rating
SELECT
    cuisines,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rate_numeric), 2) AS average_rating
FROM restaurants
WHERE cuisines IS NOT NULL
  AND rate_numeric IS NOT NULL
GROUP BY cuisines
HAVING COUNT(*) >= 50
ORDER BY restaurant_count DESC;

-- Q17: Online ordering vs rating and cost
SELECT
    online_order,
    ROUND(AVG(rate_numeric), 2) AS average_rating,
    ROUND(AVG(approx_cost_for_two), 2) AS average_cost_for_two,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE online_order IS NOT NULL
  AND rate_numeric IS NOT NULL
  AND approx_cost_for_two IS NOT NULL
GROUP BY online_order
ORDER BY online_order;

-- Q18: Table booking vs rating and votes (strongest signal in the dataset)
SELECT
    book_table,
    ROUND(AVG(rate_numeric), 2) AS average_rating,
    ROUND(AVG(votes), 0) AS average_votes,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE book_table IS NOT NULL
  AND rate_numeric IS NOT NULL
  AND votes IS NOT NULL
GROUP BY book_table
ORDER BY book_table;

-- Q19: Combined book_table + online_order effect
SELECT
    book_table,
    online_order,
    ROUND(AVG(rate_numeric), 2) AS average_rating,
    ROUND(AVG(votes), 0) AS average_votes,
    ROUND(AVG(approx_cost_for_two), 2) AS average_cost_for_two,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE book_table IS NOT NULL
  AND online_order IS NOT NULL
  AND rate_numeric IS NOT NULL
  AND votes IS NOT NULL
  AND approx_cost_for_two IS NOT NULL
GROUP BY book_table, online_order
ORDER BY book_table, online_order;

-- Q20: book_table effect on synthetic order value (indirect/mediated relationship via cost)
SELECT
    book_table,
    ROUND(AVG(order_value), 2) AS average_order_value,
    COUNT(*) AS order_count
FROM merged_orders
WHERE book_table IS NOT NULL
  AND order_value IS NOT NULL
GROUP BY book_table
ORDER BY book_table;
