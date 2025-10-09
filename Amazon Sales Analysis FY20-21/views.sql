/*------------------------------------------- IMPLEMENTING VIEWS ----------------------------------------------------*/

-- View to get product details with its category name.

create view view_productCategories as
select p.*, c.category_name
from dim_products p
join dim_categories c
	on p.category_id = c.category_id;

select * from view_productCategories;

-- View to get a summary of orders placed by each customer.

create view view_customerOrders as
select concat(first_name, ' ', last_name) as customer_name, c.*, 
	o.order_id, o.order_date, o.order_status, o.payment_method, 
	oi.order_item_id, oi.qty_ordered, oi.price, p.product_id
from fact_orders o
join dim_customers c
	on o.customer_id = c.customer_id
join dim_products p
	on o.product_id = p.product_id
join dim_order_items oi
	on o.order_item_id = oi.order_item_id;

select * from view_customerOrders;

-- Query 1: Retrieve products within a specific price range (500 to 1000).

select product_sku, price
from view_productCategories
where price between 500 and 1000;

-- Query 2: Count the number of products in each category.

select category_name, count(product_id) as no_of_products
from view_productCategories
group by category_name;

-- Query 3: Retrieve customers with more than 1 order.

select customer_name, count(order_id) as no_of_orders
from view_customerOrders
group by customer_name
	having count(order_id) > 1;

-- Query 4: Retrieve the Total Amount Spent by Each Customer.

select customer_name, sum(qty_ordered * price) as total_amount_spent
from view_customerOrders
group by customer_name;

-- Query 5: Retrieve Last 10 Orders Above a Certain Amount (1000).

select order_id, sum(qty_ordered * price) as sales_amount
from view_customerOrders
group by order_id
	having sum(qty_ordered * price) > 1000
order by sum(qty_ordered * price) desc
limit 10;

-- Query 6: Retrieve the Latest Order for Each Customer.

with cte as (
	select customer_name, order_id, order_date,
		dense_rank() over(partition by customer_name order by order_date desc) as rank
		--row_number() over(partition by customer_name order by order_date desc) as rn
	from view_customerOrders
	)
select customer_name, order_id, order_date from cte
where rank = 1;

-- Query 7: Retrieve Products in a Specific Category (Kids).

select product_sku
from view_productCategories
where category_name like '%Kids%';

-- Query 8: Retrieve Total Sales for Each Category.

select category_name, sum(qty_ordered * c.price) as total_sales
from view_customerOrders c
join view_productCategories p
	on c.product_id = p.product_id
group by category_name;

-- Query 9: Retrieve Customer Orders with Product Details.

select c.*, p.*
from view_customerOrders c
join view_productCategories p
	on c.product_id = p.product_id;

-- Query 10: Retrieve Top 5 Customers by Total Spending.

with cte as (
	select customer_name, sum(qty_ordered * price) as total_spending, 
		dense_rank() over(order by sum(qty_ordered * price) desc) as rank
	from view_customerOrders
	group by customer_name
	)
select customer_name, total_spending from cte where rank <= 5;

-- Query 11: Retrieve Products with zero discount value.

select product_sku
from view_productCategories
where discount_percent = 0;

-- Query 12: Retrieve Orders Placed in the Last 7 Days.

with cte as (
	select *, dense_rank() over(order by order_date desc) as rank
	from view_customerOrders
	)
select * from cte where rank <= 7;

-- Query 13: Retrieve Products Sold in the Last Month.

with cte as (
	select product_sku, order_date, extract(month from order_date) as month_no, extract(year from order_date) as year_no
	from view_customerOrders c
	join view_productCategories p
		on c.product_id = p.product_id
	)
select * from cte
where month_no = 12 and year_no = 2021;









