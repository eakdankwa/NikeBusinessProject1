/*
Question #1: 
If we exclude the discounts that have been given, the expected profit margin for each product is calculated by: (retail price - cost) / retail price. 

Create a column that flags products with a name that includes �Vintage� as products from Nike Vintage and Nike Official otherwise. 

Calculate the expected profit margins for each product name and include the group that splits products between Nike Official and Nike Vintage in the result.
*/

-- Question #1 Solution:
SELECT CASE WHEN product_name LIKE '%Vintage%' THEN 'Nike Vintage'
	ELSE 'Nike Official'
	END AS business_unit,
	 product_name,
	 (retail_price-cost) / retail_price AS profit_margin
FROM products;






/*
Question #2: 
What is the profit margin for each distribution center? Are there any centers that stand out?
*/
-- Question #2 Solution:
SELECT d.name,
	SUM((p.retail_price - p.cost))/ SUM(p.retail_price) AS profit_margin
FROM products AS p
INNER JOIN distribution_centers AS d
USING (distribution_center_id)
GROUP BY d.name
ORDER BY profit_margin DESC;

/* Are there any centers that stand out? 
Ans: YES. Memphis TN has the highest profit_margin whilst 
New Orleans LA has the lowest profit_margin */



/*
Question #3: 
The real profit margin per order item is calculated by: (sales price - cost) / sales price. By summing up all the order items, we will find the real profit margin generated by the products.

Calculate the profit margin for the Nike Official products: Nike Pro Tights, Nike Dri-FIT Shorts, and Nike Legend Tee
*/

-- Question #3 Solution:
SELECT p.product_name,
	SUM((oi.sale_price - p.cost)) / SUM(oi.sale_price) AS profit_margin /*By summing up all the order items, we will find the real profit margin generated by the products */
FROM products AS p
INNER JOIN order_items AS oi
USING(product_id)
WHERE product_name IN ('Nike Pro Tights', 'Nike Dri-FIT Shorts', 'Nike Legend Tee')
GROUP BY p.product_name
;
	



/*
Question #4: 
Calculate the real profit margin by product and split the data using the created date before 2021-05-01 and post 2021-05-01 for Nike Official order items.
*/

-- Question #4 Solution:
SELECT DISTINCT p.product_name,
	 CASE WHEN oi.created_at < '2021-05-01' THEN 'Pre-May'
  	WHEN oi.created_at > '2021-05-01' THEN 'Post-May'
    END AS may21_split,
  SUM((oi.sale_price - p.cost))/ SUM(oi.sale_price) AS profit_margin 
FROM order_items AS oi
INNER JOIN products AS p
USING(product_id)
WHERE CASE WHEN oi.created_at < '2021-05-01' THEN 'Pre-May'
  	WHEN oi.created_at > '2021-05-01' THEN 'Post-May'
    END IS NOT NULL
GROUP BY may21_split,
	p.product_name
ORDER BY p.product_name;






/*
Question #5: 
Calculate the profit margin by product for both Nike Official and Nike Vintage products in a single view 
*/

-- Question #5 Solution:
SELECT p.product_name,
  SUM((oi.sale_price - p.cost))/SUM(oi.sale_price) AS profit_margin
FROM order_items AS oi
INNER JOIN products AS p
USING(product_id)
GROUP BY p.product_name

UNION DISTINCT
SELECT p.product_name,
  SUM((ov.sale_price - p.cost))/ SUM(ov.sale_price) AS profit_margin
FROM order_items_vintage AS ov
INNER JOIN products AS p
USING(product_id)
GROUP BY p.product_name
;




/*
Question #6: 
What are the top 10 products by profit margin from Nike Official and Nike Vintage? 
Include the product name, profit margin, and what business unit (Nike Official or Nike Vintage) sells the product.
*/

SELECT CASE WHEN product_name LIKE '%Vintage%' THEN 'Nike Vintage'
		ELSE 'Nike Official'
       END AS business_unit,
	 products.product_name,
	 (SUM(order_items.sale_price)-SUM(products.cost)) / SUM(order_items.sale_price) AS profit_margin

FROM order_items
LEFT JOIN products ON products.product_id = order_items.product_id
          
GROUP BY products.product_name

UNION ALL

SELECT CASE WHEN product_name LIKE '%Vintage%' THEN 'Nike Vintage'
		ELSE 'Nike Official'
       END AS business_unit,
	 products.product_name,
	 (SUM(order_items_vintage.sale_price)-SUM(products.cost)) / SUM(order_items_vintage.sale_price) AS profit_margin

FROM order_items_vintage
 LEFT JOIN products ON products.product_id = order_items_vintage.product_id
          
GROUP BY products.product_name

ORDER BY profit_margin DESC

LIMIT 10;
