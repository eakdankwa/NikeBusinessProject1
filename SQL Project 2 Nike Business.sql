/*
Question #1: 
What are the unique states values available in the customer data? Count the number of customers associated to each state.

Expected columns: state, total_customers
*/

-- q1 solution: 
SELECT 
state AS state,
COUNT(customer_id) AS total_customers
FROM customers
GROUP BY 1 --  using GROUP BY statement groups the unique sates values
ORDER BY 1
;


/*
Question #2: It looks like the state data is not 100% clean and your manager already one issue:
(1) We have a value called “US State” which doesn’t make sense.

After a careful investigation your manager concluded that the “US State” customers should be assigned to California.

What is the total number of orders that have been completed for every state? Only include orders for which customer data is available.

Expected columns: clean_state, total_completed_orders

*/

-- q2 solution:
SELECT
 CASE WHEN LOWER(cus.state) LIKE '%us state%' THEN 'california'
 ELSE LOWER(cus.state) 
 END AS clean_state,
 COUNT(ord.order_id) AS total_completed_orders
 
 
FROM customers cus
INNER JOIN orders ord ON cus.customer_id = ord.user_id
WHERE ord.status IN ('Complete') -- ord.order_id IS NOT NULL statement is not necessary since then join is an inner join
GROUP BY 1
ORDER BY 1
;


/*
Question #3: After excluding some orders since the customer information was not available, your manager gets back to and stresses what we can never presented a number that is missing any orders even if our customer data is bad.

What is the total number of orders, number of Nike Official orders, and number of Nike Vintage orders that are completed by every state?

If customer data is missing, you can assign the records to ‘Missing Data’.

Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders
*/

-- q3 solution:

SELECT CASE WHEN customers.state = 'US State' THEN 'California'
   ELSE COALESCE(customers.state, 'Missing Data')
   END AS clean_state,
   COUNT(DISTINCT orders.order_id) AS total_completed_orders,
   COUNT(DISTINCT official.order_id) AS official_completed_orders,
   COUNT(DISTINCT vintage.order_id) AS vintage_completed_orders

FROM orders
                 LEFT JOIN order_items official ON official.order_id = orders.order_id
     LEFT JOIN order_items_vintage vintage ON vintage.order_id = orders.order_id
     LEFT JOIN customers ON orders.user_id = customers.customer_id
     
WHERE orders.status = 'Complete'

GROUP BY clean_state
ORDER BY 1;
 

/*
Question #4: When reviewing sales performance, there is one metric we can never forget; revenue. 

Reuse the query you created in question 3 and add the revenue (aggregate of the sales price) to your table: 
(1) Total revenue for the all orders (not just the completed!)

Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_revenue

*/

-- q4 solution:

WITH temp_table AS (
  SELECT CASE WHEN state = 'US State' THEN 'California'
  WHEN state IS Null THEN 'Missing Data'
  ELSE state
  END AS cleaned_state, 
  SUM (sale_price) AS total_revenue
  FROM order_items
  FULL JOIN customers
  ON customers.customer_id = order_items.user_id
  GROUP BY cleaned_state
     UNION ALL
 SELECT CASE WHEN state = 'US State' THEN 'California'
WHEN state IS NUll THEN 'Missing Data'
  ELSE state
  END AS cleaned_state, sum(sale_price) AS total_revenue
 FROM order_items_vintage
 FULL JOIN customers
 ON customers.customer_id = order_items_vintage.user_id
  group by cleaned_state
 ),  

complete_orders AS (
  SELECT CASE WHEN customers.state = 'US State' THEN 'California'
	 WHEN customers.state IS NULL THEN 'Missing Data'
   ELSE customers.state
   END AS cleaned_state,
   COUNT(DISTINCT orders.order_id) AS total_completed_orders,
   COUNT(DISTINCT official.order_id) AS official_completed_orders,
   COUNT(DISTINCT vintage.order_id) AS vintage_completed_orders
   
FROM orders
   LEFT JOIN order_items official ON official.order_id = orders.order_id
   LEFT JOIN order_items_vintage vintage ON vintage.order_id = orders.order_id
   LEFT JOIN customers ON orders.user_id = customers.customer_id
   WHERE orders.status = 'Complete'
GROUP BY 1)

SELECT complete_orders.cleaned_state,
	complete_orders.total_completed_orders, 
  complete_orders.official_completed_orders,
  complete_orders.vintage_completed_orders, 
  SUM (temp_table.total_revenue) AS total_revenue 
FROM complete_orders
FULL JOIN temp_table ON complete_orders.cleaned_state = temp_table.cleaned_state
GROUP BY 1, 2, 3, 4; -- solution

/*
Question #5: The leadership team is also interested in understanding the number of order items that get returned. 

Reuse the query of question 4 and add an additional metric to the table: 
(1) Number of order items that have been returned (items where the return date is populated)

Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_revenue,returned_items


*/

-- q5 solution:

WITH temp_table AS (
  SELECT CASE WHEN state = 'US State' THEN 'California'
  WHEN state IS Null THEN 'Missing Data'
  ELSE state
  END AS cleaned_state, 
  SUM (sale_price) AS total_revenue,
  COUNT (returned_at ) AS items_returned
  FROM order_items
  FULL JOIN customers
  ON customers.customer_id = order_items.user_id
  GROUP BY cleaned_state
     UNION ALL
 SELECT CASE WHEN state = 'US State' THEN 'California'
WHEN state IS NUll THEN 'Missing Data'
  ELSE state
  END AS cleaned_state, 
  SUM(sale_price) AS total_revenue,
	COUNT (returned_at ) AS items_returned
 FROM order_items_vintage
 FULL JOIN customers
 ON customers.customer_id = order_items_vintage.user_id
  GROUP BY cleaned_state
 ),  

complete_orders AS (
  SELECT CASE WHEN customers.state = 'US State' THEN 'California'
	 WHEN customers.state IS NULL THEN 'Missing Data'
   ELSE customers.state
   END AS cleaned_state,
   COUNT(DISTINCT orders.order_id) AS total_completed_orders,
   COUNT(DISTINCT official.order_id) AS official_completed_orders,
   COUNT(DISTINCT vintage.order_id) AS vintage_completed_orders
   
   
FROM orders
   LEFT JOIN order_items official ON official.order_id = orders.order_id
   LEFT JOIN order_items_vintage vintage ON vintage.order_id = orders.order_id
   LEFT JOIN customers ON orders.user_id = customers.customer_id
   WHERE orders.status = 'Complete'
GROUP BY 1)

SELECT complete_orders.cleaned_state,
	complete_orders.total_completed_orders, 
  complete_orders.official_completed_orders,
  complete_orders.vintage_completed_orders, 
  SUM(temp_table.total_revenue) AS total_revenue,
  SUM(items_returned) AS returned_items
  FROM complete_orders
FULL JOIN temp_table ON complete_orders.cleaned_state = temp_table.cleaned_state
GROUP BY 1, 2, 3, 4;

/*
Question #6: When looking at the number of returned items by itself, it is hard to understand what number of returned items is acceptable. This is mainly caused by the fact that we don’t have a benchmark at the moment.

Because of that, it is valuable to add an additional metric that looks at the percentage of returned order items divided by the total order items, we can call this the return rate.

Reuse the query of question 5 and integrate the return rate into your table.

Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_revenue,returned_items,return_rate


*/

-- q6 solution:

WITH temp_table AS (
  SELECT CASE WHEN state = 'US State' THEN 'California'
  WHEN state IS NULL THEN 'Missing Data'
  ELSE state
  END AS cleaned_state, 
  SUM (sale_price) AS total_revenue,
  COUNT (returned_at ) AS items_returned,
  COUNT(order_id) AS items_ordered
  FROM order_items
  FULL JOIN customers
  ON customers.customer_id = order_items.user_id
  GROUP BY cleaned_state
     UNION ALL
 SELECT CASE WHEN state = 'US State' THEN 'California'
WHEN state IS NULL THEN 'Missing Data'
  ELSE state
  END AS cleaned_state, 
  SUM(sale_price) AS total_revenue,
	COUNT (returned_at ) AS items_returned,
  COUNT(order_id) AS items_ordered
 FROM order_items_vintage
 FULL JOIN customers
 ON customers.customer_id = order_items_vintage.user_id
  GROUP BY cleaned_state
 ),  

complete_orders AS (
  SELECT CASE WHEN customers.state = 'US State' THEN 'California'
	 WHEN customers.state IS NULL THEN 'Missing Data'
   ELSE customers.state
   END AS cleaned_state,
   COUNT(DISTINCT orders.order_id) AS total_completed_orders,
   COUNT(DISTINCT official.order_id) AS official_completed_orders,
   COUNT(DISTINCT vintage.order_id) AS vintage_completed_orders
FROM orders
   LEFT JOIN order_items official ON official.order_id = orders.order_id
   LEFT JOIN order_items_vintage vintage ON vintage.order_id = orders.order_id
   LEFT JOIN customers ON orders.user_id = customers.customer_id
   WHERE orders.status = 'Complete'
GROUP BY 1)
   
SELECT complete_orders.cleaned_state,
	complete_orders.total_completed_orders, 
  complete_orders.official_completed_orders,
  complete_orders.vintage_completed_orders, 
  SUM(temp_table.total_revenue) AS total_revenue,
  SUM(items_returned) AS returned_items,
  SUM(items_returned)/SUM(items_ordered) AS return_rate
  FROM complete_orders
FULL JOIN temp_table ON complete_orders.cleaned_state = temp_table.cleaned_state
GROUP BY 1, 2, 3, 4; -- solution