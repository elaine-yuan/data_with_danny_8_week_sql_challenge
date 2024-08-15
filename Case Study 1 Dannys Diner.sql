/* --------------------
  Danny's Diner Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_amount_spent
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
GROUP BY 1
ORDER BY 2 DESC
;

-- ANSWERS
-- A spent $76
-- B spent $74
-- C spent $36

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as days_visited
FROM sales
GROUP BY 1
ORDER BY 2 DESC
;

-- ANSWERS
-- B visited 6 times
-- A visited 4 times
-- C visited 2 times

-- 3. What was the first item from the menu purchased by each customer?
-- ASSUMPTION: if the first order includes multiple items, the first item purchased is based on product_id

WITH items_purchased AS (
SELECT s.customer_id, s.order_date, m.product_name, RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date, s.product_id ASC) AS rank
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
GROUP BY 1, 2, 3, s.product_id
)
SELECT customer_id, product_name as first_purchased_product
FROM items_purchased
WHERE rank=1
;

-- ANSWERS
-- A first purchased sushi
-- B first purchased curry
-- C first purchased ramen

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(s.product_id)
FROM menu m
LEFT JOIN sales s
ON s.product_id=m.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
;

-- ANSWERS
-- ramen is the most purchased items
-- it was purchased 8 times

-- 5. Which item was the most popular for each customer?
-- ASSUMPTION: most popular = most often purchased 

WITH ranked_products_purchased AS(
WITH products_purchased AS(
SELECT s.customer_id, m.product_name, COUNT(s.product_id) as product_count
FROM menu m
LEFT JOIN sales s
ON s.product_id=m.product_id
GROUP BY 1, 2
ORDER BY 2 DESC
)
SELECT *, RANK() OVER (PARTITION BY customer_id ORDER BY product_count DESC) AS rank
FROM products_purchased
)
SELECT customer_id, product_name, product_count
FROM ranked_products_purchased
WHERE rank=1
;

-- ANSWERS
-- ramen was the most popular for A
-- all 3 items (ramen, sushi, curry) are equally popular for B
-- ramen is the most popular for C

-- 6. Which item was purchased first by the customer after they became a member?

WITH items_as_member AS (
SELECT s.customer_id, s.order_date, m.product_name, RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS rank
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date<=s.order_date
GROUP BY 1, 2, 3
)
SELECT customer_id, product_name
FROM items_as_member
WHERE rank=1
;

-- ANSWERS
-- A bought curry after becoming a member
-- B bought sushi after becoming a member

--data validate
--SELECT s.customer_id, mm.join_date,  ----s.order_date, m.product_name
--FROM sales s
--LEFT JOIN menu m
--ON s.product_id=m.product_id
--LEFT JOIN members mm
--ON s.customer_id=mm.customer_id
--WHERE mm.join_date<=s.order_date
--GROUP BY 1, 2, 3, 4
--;

-- 7. Which item was purchased just before the customer became a member?
-- ASSUMPTION: if the first order includes multiple items, the last item purchased is based on product_id

WITH items_before_member AS (
SELECT s.customer_id, s.order_date, m.product_name, RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date, m.product_id DESC) AS rank
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date>s.order_date
GROUP BY 1, 2, 3, m.product_id
)
SELECT customer_id, product_name
FROM items_before_member
WHERE rank=1
;

-- ANSWERS
-- customers A and B last purchased curry before becoming members

--data validate
--SELECT s.customer_id, mm.join_date, s.order_date, m.product_name
--FROM sales s
--LEFT JOIN menu m
--ON s.product_id=m.product_id
--LEFT JOIN members mm
--ON s.customer_id=mm.customer_id
--WHERE mm.join_date>s.order_date
--GROUP BY 1, 2, 3, 4
--;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(m.price) as amount_spent
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date>s.order_date
GROUP BY 1
;

-- ANSWERS
-- B bought 3 items and spent $40 before becoming a member
-- A bought 2 items and spent $25 before becoming a member

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- ASSUMPTION: only members can earn points

WITH unioned_tables AS(
--items that aren't sushi - $1 = 10 points
SELECT s.customer_id, SUM(m.price), SUM(m.price)*10 AS points
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date<=s.order_date
AND m.product_name!='sushi'
GROUP BY 1
UNION
--sushi - $1 = 20 points
SELECT s.customer_id, SUM(m.price), SUM(m.price)*20 AS points
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date<=s.order_date
AND m.product_name='sushi'
GROUP BY 1
)
SELECT customer_id, SUM(points) as total_points
FROM unioned_tables
GROUP BY 1
;

-- ANSWERS
-- A has 510 points
-- B has 440 points

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH unioned_cte AS(
--first week - all items - $1 = 20 points
SELECT s.customer_id, s.order_date, mm.join_date, DATEDIFF(day, mm.join_date,s.order_date) as date_diff, SUM(m.price), SUM(m.price)*20 AS points
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date <= s.order_date
AND date_diff<=6
GROUP BY 1, 2, 3, 4
UNION
--items that aren't sushi - $1 = 10 points
SELECT s.customer_id, s.order_date, mm.join_date, DATEDIFF(day, mm.join_date,s.order_date) as date_diff, SUM(m.price), SUM(m.price)*10 AS points
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date<=s.order_date
AND m.product_name!='sushi'
AND date_diff>6
AND EXTRACT(month FROM s.order_date)=1
GROUP BY 1, 2, 3, 4
UNION
--sushi - $1 = 20 points
SELECT s.customer_id, s.order_date, mm.join_date, DATEDIFF(day, mm.join_date,s.order_date) as date_diff, SUM(m.price), SUM(m.price)*20 AS points
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date<=s.order_date
AND m.product_name='sushi'
AND date_diff>6
AND EXTRACT(month FROM s.order_date)=1
GROUP BY 1, 2, 3, 4
)
SELECT customer_id, SUM(points) as total_points
FROM unioned_cte
GROUP BY 1
;

-- ANSWERS
-- A has 1020 points
-- B has 440 points

/* --------------------
  Bonus Questions
   --------------------*/

--Join All The Things

SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE 
    WHEN mm.join_date <= s.order_date THEN 'Y'
    ELSE 'N'
END AS member
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
ORDER BY s.customer_id, s.order_date ASC
;

--Rank All The Things

WITH unioned_cte AS(
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
    WHEN mm.join_date <= s.order_date THEN 'Y'
    ELSE 'N'
END AS member, RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as ranking
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date <= s.order_date
UNION
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
    WHEN mm.join_date <= s.order_date THEN 'Y'
    ELSE 'N'
END AS member, 
CASE 
	WHEN mm.join_date <= s.order_date THEN RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date)
    ELSE NULL
END as ranking
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mm
ON s.customer_id=mm.customer_id
WHERE mm.join_date > s.order_date
)
SELECT *
FROM unioned_cte
ORDER BY 1, 2
;