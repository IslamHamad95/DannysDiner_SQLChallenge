--1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, count(customer_id) AS num_of_visits 
FROM sales
GROUP BY customer_id

--2. How many days has each customer visited the restaurant?
 --Uing CTE
WITH CTE AS(
	SELECT DISTINCT customer_id,  order_date 
	FROM sales)
SELECT customer_id, COUNT (order_date) AS num_of_days 
FROM CTE
GROUP BY customer_id

--Using Sup queries:
SELECT customer_id, COUNT(order_date) AS num_of_days 
FROM (
	SELECT DISTINCT customer_id, order_date 
	FROM sales
) AS x
GROUP BY customer_id

--3. What was the first item from the menu purchased by each customer?
WITH firstItem AS(
	SELECT ROW_NUMBER() over (partition by customer_id order by customer_id,order_date) As order_rank,customer_id,order_date,product_id
	FROM sales
)
SELECT customer_id,order_date, m.product_name
FROM cte s
LEFT JOIN menu m ON m.product_id=s.product_id
WHERE  order_rank=1


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 m.product_name, count(s.product_id) AS most_bought 
FROM sales s
LEFT JOIN menu m on m.product_id=s.product_id
GROUP BY m.product_name
ORDER BY most_bought DESC

--5. Which item was the most popular for each customer?
WITH RankedProducts AS (
    SELECT
        row_number() OVER (PARTITION BY customer_id ORDER BY customer_id, COUNT(s.product_id) DESC) AS rnk,
        customer_id,
        product_name,
        COUNT(s.product_id) AS most_popular
    FROM sales s
    LEFT JOIN menu m ON m.product_id = s.product_id
    GROUP BY customer_id, product_name
)
SELECT customer_id, product_name, most_popular
FROM RankedProducts
WHERE rnk = 1;


--6. Which item was purchased first by the customer after they became a member?
WITH FirstPurchase AS (
    SELECT s.customer_id,MIN(s.order_date) AS first_order_date
    FROM sales s
    LEFT JOIN members m ON s.customer_id = m.customer_id
    WHERE m.join_date <= s.order_date
    GROUP BY s.customer_id
)
SELECT
    s.customer_id,fp.first_order_date,mu.product_name
FROM FirstPurchase fp
JOIN sales s ON fp.customer_id = s.customer_id AND fp.first_order_date = s.order_date
LEFT JOIN menu mu ON s.product_id = mu.product_id;
 
--7. Which item was purchased just before the customer became a member?
WITH LastPurchase AS (    
	SELECT s.customer_id,MAX(s.order_date) AS last_order_date 
    FROM sales s
    LEFT JOIN members m ON s.customer_id = m.customer_id
    WHERE m.join_date > s.order_date
    GROUP BY s.customer_id
)
SELECT s.customer_id, last_order_date, mu.product_name
FROM LastPurchase lp
LEFT JOIN sales s ON lp.customer_id = s.customer_id AND lp.last_order_date = s.order_date
LEFT JOIN menu mu ON s.product_id = mu.product_id;

--8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,count(s.order_date) AS no_of_items,SUM(mu.price) AS total
FROM sales s
LEFT JOIN menu mu on s.product_id=mu.product_id
LEFT JOIN members m on s.customer_id= m.customer_id
WHERE s.order_date< m.join_date
GROUP BY s.customer_id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH TotalPoints AS(
SELECT s.customer_id,mu.product_name,
CASE
	WHEN Product_name like 'sushi' THEN SUM(mu.price)*20
	ELSE SUM(mu.price)*10
END AS points
FROM sales s
LEFT JOIN menu mu on s.product_id=mu.product_id
GROUP BY s.customer_id, mu.product_name
)
SELECT customer_id, sum(points) as total_points
FROM TotalPoints
GROUP BY customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,count(mu.product_name) AS no_of_items, COUNT(mu.product_name)*2 AS total_points
FROM sales s
LEFT JOIN members m ON s.customer_id=m.customer_id
LEFT JOIN menu mu ON s.product_id= mu.product_id
where s.order_date>=m.join_date and s.order_date< '2021-02-01'
GROUP BY s.customer_id
