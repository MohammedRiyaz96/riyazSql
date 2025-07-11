---------------------------------------- AMAZON SALES ANALYSIS (FY2020 - 2021) ----------------------------------------------

--Query 1: Retrieve all order details with customer (name, email, gender and region).

select concat(first_name, ' ', last_name) as customer_name, o.customer_id, gender, e_mail, region,
	o.order_id, order_date, oi.order_item_id, p.product_id, product_sku, qty_ordered, order_status
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
join dim_products p
	on o.product_id = p.product_id
join dim_order_items oi
	on o.order_item_id = oi.order_item_id;


--Query 2: Find the total sales for each product.

select product_sku, sum(qty_ordered * oi.price) as total_sales
from dim_products p
join dim_order_items oi
	on p.product_id = oi.product_id
group by product_sku;


--Query 3: Calculate the average sales of all products.

select round(cast(avg(qty_ordered * price) as decimal), 2) as avg_sales_all_products
from dim_order_items;


--Query 4: List the top 5 customers by total spending.

with cte as (
	select 
		concat(first_name, ' ', last_name) as customer_name, 
		round(cast(sum(qty_ordered * price) as decimal), 2) as total_spending,
		dense_rank() over(order by round(cast(sum(qty_ordered * price) as decimal), 2) desc) as rank
	from fact_orders o
	join dim_order_items oi
		on o.order_item_id = oi.order_item_id
	join dim_customers c
		on o.customer_id = c.customer_id
	group by concat(first_name, ' ', last_name)
	)
select customer_name, total_spending from cte where rank <= 5;


--Query 5: Retrieve the most popular product category.

with cte as (
	select category_name, sum(qty_ordered) as total_quantity_sold, dense_rank() over(order by sum(qty_ordered) desc) as rank
	from dim_products p
	join dim_order_items oi
		on p.product_id = oi.product_id
	join dim_categories cat
		on p.category_id = cat.category_id
	group by category_name
	)
select category_name, total_quantity_sold from cte where rank = 1;


--Query 6: List all products that have discount value with category name.

select category_name, product_sku, discount_percent
from dim_products p
join dim_categories cat
	on p.category_id = cat.category_id
where discount_percent != 0;


--Query 7: Identify the best selling product category for each state.

with cte as (
	select 
		state, 
		category_name, 
		sum(qty_ordered) as total_qty, 
		dense_rank() over(partition by state order by sum(qty_ordered) desc) as rank
	from dim_products p
	join dim_categories cat
		on p.category_id = cat.category_id
	join dim_order_items oi
		on p.product_id = oi.product_id
	join fact_orders o
		on p.product_id = o.product_id
	join dim_customers c
		on o.customer_id = c.customer_id
	--where state in ('MO', 'IN')
	group by state, category_name
	)
select state, category_name, total_qty from cte where rank = 1;


--Query 8: Calculate the total number of orders placed each month.

select to_char(order_date, 'Month') as month, count(order_id) as total_orders
from fact_orders
group by to_char(order_date, 'Month'), extract(month from order_date)
order by extract(month from order_date);


--Query 9: Retrieve the details of the most recent date orders.

with cte as (
	select concat(first_name, ' ', last_name) as customer_name, o.customer_id, o.order_id, order_date, 
		oi.order_item_id, p.product_id, product_sku, qty_ordered, order_status,
		rank() over(order by order_date desc) as rank
	from fact_orders o
	join dim_customers c
		on o.customer_id = c.customer_id
	join dim_products p
		on o.product_id = p.product_id
	join dim_order_items oi
		on o.order_item_id = oi.order_item_id
	)
select * from cte where rank = 1;


--Query 10: Find the average price of products in each category.

select category_name, round(cast(avg(price) as decimal), 2) as avg_price
from dim_products p
join dim_categories cat
	on p.category_id = cat.category_id
group by category_name;


--Query 11: List customers who have never placed an order.

select c.customer_id, concat(first_name, ' ', last_name) as customer_name
from fact_orders o
right join dim_customers c
	on o.customer_id = c.customer_id
where order_id is null;


--Query 12: Retrieve the total quantity sold for each product in descending order. Find the top 3 best selling categories.

-- Total quantity sold for each product in descending order:
select product_sku, sum(qty_ordered) as total_qty_sold_per_product
from dim_products p
join dim_order_items oi
	on oi.product_id = p.product_id
group by product_sku
order by sum(qty_ordered) desc;

-- Top 3 best selling categories: 
with cte as (
	select 
		category_name, 
		sum(qty_ordered) as total_qty_sold_per_category, 
		dense_rank() over(order by sum(qty_ordered) desc) as rank
	from dim_products p
	join dim_order_items oi
		on oi.product_id = p.product_id
	join dim_categories cat
		on p.category_id = cat.category_id
	group by category_name
	)
select category_name, total_qty_sold_per_category from cte where rank <= 3;


/* Query 13: Calculate the total revenue generated from each category (with percentage contribution of each category 
to total revenue).
*/

with cte as (
	select category_name, round(cast(sum(qty_ordered * oi.price) as decimal),2) as total_revenue_each_category
	from dim_products p
	join dim_order_items oi
		on oi.product_id = p.product_id
	join dim_categories cat
		on p.category_id = cat.category_id
	group by category_name
	)
select category_name, total_revenue_each_category, 
	(total_revenue_each_category / (select sum(qty_ordered * price) from dim_order_items)) * 100 as percentage_contribution
from cte;


--Query 14: Find the highest-priced product in each category.

with cte as (
	select category_name, product_sku, price, dense_rank() over(partition by category_name order by price desc) as rank
	from dim_products p
	join dim_categories cat
		on p.category_id = cat.category_id
	)
select category_name, product_sku, price as high_price_product from cte where rank = 1; 


--Query 15: Retrieve orders with a sales amount greater than 500.

select o.order_id, order_date, customer_id, p.product_id, product_sku, (qty_ordered * oi.price) as sales_amount
from fact_orders o
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
join dim_products p
	on o.product_id = p.product_id
where (qty_ordered * oi.price) > 500;


--Query 16: List products along with the number of orders they appear in.

select product_sku, count(order_id) as no_of_orders
from fact_orders o
join dim_products p
	on o.product_id = p.product_id
group by product_sku;


--Query 17: Find the top 3 most frequently ordered products.

with cte as (
	select product_sku, count(distinct(order_id)) as no_of_orders, dense_rank() over(order by count(order_id) desc) as rank
	from fact_orders o
	join dim_products p
		on o.product_id = p.product_id
	group by product_sku
	)
select product_sku, no_of_orders from cte where rank <= 3;


/* Query 18: Calculate the total number of customers from each country. Also, identify the top 5 customers with the highest 
number of orders for each state and number of orders for each customer. */

-- Total number of customers from each country:
select country, count(customer_id)
from dim_customers
group by country;

-- Top 5 customers with the highest number of orders for each state and number of orders for each customer.
with cte as (
	select 
		state, 
		concat(first_name, ' ', last_name) as customer_name, 
		count(distinct(order_id)) as no_of_orders,
		dense_rank() over(partition by state order by count(distinct(order_id)) desc) as rank
	from dim_customers c
	join fact_orders o
		on c.customer_id = o.customer_id
	group by state, customer_name
	)
select state, customer_name, no_of_orders from cte where rank <= 5;


--Query 19: Display the total sales and average sales done for each day.

select order_date, sum(qty_ordered * price) as total_sales, avg(qty_ordered * price) as avg_sales
from fact_orders o
join dim_order_items oi
	on o.order_item_id = o.order_item_id
group by order_date; 


--Query 20: List orders with more than 5 items.

select o.order_id, count(oi.order_item_id) as no_of_items
from fact_orders o
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
group by o.order_id
	having count(oi.order_item_id) > 5;


/* Query 21: Other than complete, display the available order status with order id, order_date and product_name.
Show the earliest orders at the top. Also display the customers who purchased these orders. */

select concat(first_name, ' ', last_name) as customer_name, order_id, order_date, product_sku, order_status 
from fact_orders o
join dim_products p
	on o.product_id = p.product_id
join dim_customers c
	on o.customer_id = c.customer_id
where order_status != 'complete'
order by order_date desc;


/* Query 22: Display the total no of orders corresponding to each order status. Status with highest no of orders 
should be at the top. */

select order_status, count(distinct(order_id)) as total_orders
from fact_orders
group by order_status
order by count(order_id) desc;


--Query 23: For orders purchasing more than 1 item, how many are still not completed?

select o.order_id, count(oi.order_item_id) as total_items
from fact_orders o
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
where order_status != 'complete'
group by o.order_id
	having count(oi.order_item_id) > 1;


/* Query 24: Write a query to identify the total products purchased by each customer. Return all customers 
irrespective of whether they have made a purchase or not. Sort the result in descending. */

select concat(first_name, ' ', last_name) as customer_name, coalesce(sum(qty_ordered), 0) as total_products
from fact_orders o
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
right join dim_customers c
	on o.customer_id = c.customer_id
--where o.order_id is null
group by (concat(first_name, ' ', last_name))
order by coalesce(sum(qty_ordered), 0) desc;


--Query 25: Display the customer name and total sale amount of all orders which are either on hold or pending.

select concat(first_name, ' ', last_name) as customer_name, sum(qty_ordered * price) as total_sales
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
where order_status like '%hold%' or order_status like '%pending%' or order_status like '%process%'
group by concat(first_name, ' ', last_name);


/* Query 26: Fetch all the orders which were neither completed/pending, and was ordered by Mellisa. 
Display customer name and all details of order. */

select first_name, o.*
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
where order_status != 'complete' and order_status not like '%hold%' and order_status not like '%pending%' and 
order_status not like '%process%' and first_name = 'Mellisa';


--Query 27: Identify the customers who have purchased more than 5 products.

select concat(first_name, ' ', last_name) as customer_name, sum(qty_ordered) as purchased_products
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
group by concat(first_name, ' ', last_name)
	having sum(qty_ordered) > 5;


--Query 28: Identify customers whose average purchase cost exceeds the average sale of all the orders. ---

select concat(first_name, ' ', last_name) as customer_name, avg(qty_ordered * price) as avg_purchase
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
group by concat(first_name, ' ', last_name)
	having avg(qty_ordered * oi.price) > (
											select avg(qty_ordered * price) 
											from dim_order_items
											);


--Query 29: Query the top 10 products by total sales value along with total quantity sold.

with cte as (
	select 
		product_sku,
		sum(qty_ordered) as total_qty_sold,
		sum(qty_ordered * oi.price) as total_sales,
		dense_rank() over(order by sum(qty_ordered * oi.price) desc) as rank
	from dim_products p
	join dim_order_items oi
		on p.product_id = oi.product_id
	group by product_sku
	)
select product_sku, total_qty_sold, total_sales from cte where rank <= 10;


--Query 30: Calculate the average order value for each customer (only customer with more than 5 orders).

select c.customer_id, (sum(qty_ordered * oi.price)) / (count(o.order_id)) as avg_order_value
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
group by c.customer_id
	having count(o.order_id) > 5;


/* Query 31: Query monthly sales for the year 2020. Display the sales trend, grouping by month, return current month sale,
last month sale. */

select 
	extract(year from order_date) as year,
	to_char(order_date, 'Month') as month, 
	coalesce(sum(qty_ordered * price), 0) as total_sales
from fact_orders o
join dim_order_items oi
	on o.order_item_id = oi.order_item_id
group by year, month, extract(month from order_date)
	having extract(year from order_date) = 2020
order by extract(month from order_date);    -- no sales in the months other than the months shown in the result.


--Query 32: Calculate the percentage of all methods of payments across all orders.

with cte1 as (
	select 
		order_status, 
		count(order_status) over(partition by order_status) as status_count, 
		count(order_id) over() as total_orders,
		row_number() over(partition by order_status) as rn
	from fact_orders
	),
	cte2 as (
		select * from cte1 where rn = 1
		)
select order_status, status_count, total_orders, (status_count * 100) / total_orders as percent_status
from cte2;


--Query 33: Top 10 product with highest decreasing revenue ratio compare to 2020 and 2021.

with cte as (
	select 
		last_year_sales,
		current_year_sales,
		((current_year_sales - last_year_sales) / last_year_sales * 100) as revenue_dec_ratio,
		dense_rank() over(order by ((current_year_sales - last_year_sales) / last_year_sales * 100)) as rank
	from (
		select product_sku, sum(qty_ordered * oi.price) as last_year_sales
		from dim_order_items oi
		join fact_orders o
			on oi.order_id = o.order_id
		join dim_products p
			on o.product_id = p.product_id
		where extract(year from o.order_date) = 2020 and oi.price != 0
		group by product_sku
		order by last_year_sales
		) x
	join (
		select product_sku, sum(qty_ordered * oi.price) as current_year_sales
		from dim_order_items oi
		join fact_orders o
			on oi.order_id = o.order_id
		join dim_products p
			on o.product_id = p.product_id
		where extract(year from o.order_date) = 2021 and oi.price != 0
		group by product_sku
		) y
		on x.product_sku = y.product_sku
	)
select last_year_sales, current_year_sales, revenue_dec_ratio
from cte 
where rank <= 10 and current_year_sales < last_year_sales;
	 










