/* --------------------
  Pizza Runner Case Study Questions
   --------------------*/

-- PIZZA METRICS

-- 1. How many pizzas were ordered?
SELECT COUNT(pizza_id) as pizzas_ordered
FROM customer_orders
;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders
;

-- 3. How many successful orders were delivered by each runner?
SELECT COUNT(DISTINCT order_id) AS delivered_orders
FROM runner_orders
WHERE pickup_time!='null'
;

-- 4. How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(co.pizza_id) as pizzas_delivered
FROM customer_orders co
LEFT JOIN runner_orders ro
ON co.order_id=ro.order_id
LEFT JOIN pizza_names pn
ON co.pizza_id=pn.pizza_id
WHERE ro.pickup_time!='null'
GROUP BY 1
;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pn.pizza_name, COUNT(co.pizza_id) as pizzas_ordered
FROM customer_orders co
LEFT JOIN pizza_names pn
ON co.pizza_id=pn.pizza_id
GROUP BY 1, 2
ORDER BY 1, 2
;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT ro.order_id, COUNT(co.pizza_id) as pizzas_delivered
FROM customer_orders co
LEFT JOIN runner_orders ro
ON co.order_id=ro.order_id
WHERE ro.pickup_time!='null'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH status_table AS (
SELECT co.order_id, co.customer_id, co.pizza_id, co.exclusions, co.extras, 
CASE WHEN  exclusions='null' AND extras='null'  THEN 'no change' 
    WHEN exclusions IS NULL OR extras IS NULL THEN 'no change'
    WHEN  LENGTH(exclusions)=1 OR LENGTH(extras)=1  THEN 'change'
    WHEN  exclusions LIKE '%,%' OR extras LIKE '%,%'  THEN 'change'
    ELSE 'no change'
    END AS status
FROM customer_orders co
LEFT JOIN runner_orders ro
ON co.order_id=ro.order_id
WHERE ro.pickup_time!='null'
)
SELECT customer_id, status, COUNT(status) as pizza_count
FROM status_table st
RIGHT JOIN runner_orders ro ON st.order_id = ro.order_id
WHERE customer_id IS NOT NULL
GROUP BY 1, 2
ORDER BY 1
;

--data validate
--SELECT co.order_id, co.customer_id, co.pizza_id, co.exclusions, co.extras, 
--CASE WHEN  exclusions='null' AND extras='null'  THEN 'no change' 
--    WHEN exclusions IS NULL OR extras IS NULL THEN 'no change'
--    WHEN  LENGTH(exclusions)=1 OR LENGTH(extras)=1  THEN 'change'
--    WHEN  exclusions LIKE '%,%' OR extras LIKE '%,%'  THEN 'change'
--    ELSE 'no change'
--    END AS status
--FROM customer_orders co
--LEFT JOIN runner_orders ro
--ON co.order_id=ro.order_id
--WHERE ro.pickup_time!='null'
--;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(pizza_id) AS pizzas_with_exclusions_and_extras
FROM customer_orders co
LEFT JOIN runner_orders ro
ON co.order_id=ro.order_id
WHERE ro.pickup_time!='null'
AND co.exclusions!='null' AND co.exclusions IS NOT NULL
AND co.extras!='null' AND co.extras IS NOT NULL 
;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT HOUR(order_time), COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders
GROUP BY 1
ORDER BY 1 ASC
;

-- 10. What was the volume of orders for each day of the week?
SELECT CASE 
    WHEN DAYOFWEEK(order_time) = 2 THEN 'Monday'
    WHEN DAYOFWEEK(order_time) = 3 THEN 'Tuesday'
    WHEN DAYOFWEEK(order_time) = 4 THEN 'Wednesday'
    WHEN DAYOFWEEK(order_time) = 5 THEN 'Thursday'
    WHEN DAYOFWEEK(order_time) = 6 THEN 'Friday'
    WHEN DAYOFWEEK(order_time) = 7 THEN 'Saturday'
    WHEN DAYOFWEEK(order_time) = 1 THEN 'Sunday'
END AS day_of_week, COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders
GROUP BY 1
ORDER BY 2 DESC
;