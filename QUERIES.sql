-- Query 1: Total Number of complete, canceled and raud orders so far.
SELECT order_status, count(order_id) AS total_no_of_orders
FROM orders
WHERE order_status IN ( 'COMPLETE', 'CANCELED', 'SUSPECTED_FRAUD')
GROUP BY order_status;

--Query 2: Number of fraud orders per day in descending order.
SELECT order_date, COUNT(order_id) AS total_fraud_orders 
FROM orders
WHERE order_status = 'SUSPECTED_FRAUD'
GROUP BY order_date
ORDER BY total_fraud_orders DESC;

--Query 3: Total revenue per state.
SELECT c1.customer_state AS state, SUM(c.total_purchase) AS revenue
FROM customers as c1
INNER JOIN
(
	/* total purchase by each customer*/
	SELECT orders.order_customer_id AS customer_id, SUM(order_total.total) AS total_purchase
	FROM 
	( 
		/* total bill for each order*/
		SELECT order_item_order_id AS order_id, SUM(order_item_subtotal) AS total 
		FROM order_items 
		GROUP BY order_item_order_id 
		) AS order_total
		INNER JOIN orders ON order_total.order_id = orders.order_id
		WHERE order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
		GROUP BY orders.order_customer_id
) AS c
ON c.customer_id = c1.customer_id
GROUP BY c1.customer_state
ORDER BY c1.customer_state;

--Query 4: Top 10 selling product names so far.
SELECT p.product_id, p.product_name, o.no_of_units_sold
FROM products AS p
INNER JOIN 
(
	/* Top 10 product_ids of product and their sales by joining order_items and orders table */
	SELECT  o1.order_item_product_id, SUM(o1.order_item_quantity) AS no_of_units_sold
	FROM order_items AS o1
	LEFT JOIN orders AS o2 ON o1.order_item_order_id = o2.order_id
	WHERE o2.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
	GROUP BY o1.order_item_product_id
) AS o ON p.product_id = o.order_item_product_id
ORDER BY no_of_units_sold DESC
LIMIT 10;

--Query 5: Top 10 selling product names on date 2019-07-25.
SELECT p.product_id, p.product_name, o.no_of_units_sold
FROM products AS p
INNER JOIN 
(
	/* Top 10 product_ids of product and their sales by joining order_items and orders table */
	SELECT  o1.order_item_product_id, SUM(o1.order_item_quantity) AS no_of_units_sold
	FROM order_items AS o1
	LEFT JOIN orders AS o2 ON o1.order_item_order_id = o2.order_id
	WHERE o2.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD') AND o2.order_date='2019-07-25'
	GROUP BY o1.order_item_product_id
) AS o ON p.product_id = o.order_item_product_id
ORDER BY no_of_units_sold DESC
LIMIT 10;

--Query 6: Popular one product within each category.
SELECT * 
FROM 
(
	SELECT p.product_name, c.category_name, total_order.total_orders, 
		   row_number() over(partition by p.product_category_id order by total_orders desc) AS rn
	FROM 
	(	
		SELECT oi.order_item_product_id  AS product_id, COUNT(oi.order_item_order_id) AS total_orders
		FROM order_items AS oi
		LEFT JOIN orders AS o ON o.order_id = oi.order_item_order_id
		WHERE o.order_status='COMPLETE'
		GROUP BY oi.order_item_product_id
	) AS total_order
	INNER JOIN products AS p  ON total_order.product_id = p.product_id
	INNER JOIN categories AS c ON c.category_id = p.product_category_id
) AS result
WHERE result.rn=1;