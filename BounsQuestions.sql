--Join All The Things
Select s.customer_id, order_date, product_name, price,
CASE
	WHEN join_date=order_date THEN 'Y'
	ELSE 'N'
END AS member
FROM sales s
LEFT JOIN members m ON s.customer_id= m.customer_id
LEFT JOIN menu mu ON s.product_id= mu.product_id

--Rank All The Things
WITH RankingTable AS(
	Select s.customer_id, order_date, product_name, price, join_date,
	CASE
		WHEN join_date<=order_date THEN 'Y'
		ELSE 'N'
	END AS member
	FROM sales s
	LEFT JOIN members m ON s.customer_id= m.customer_id
	LEFT JOIN menu mu ON s.product_id= mu.product_id
)
SELECT *,
CASE 
	WHEN member like 'Y' 
		THEN RANK() OVER (PARTITION BY customer_id,member ORDER BY order_date)
	ELSE NULL
END AS ranking
FROM RankingTable		
