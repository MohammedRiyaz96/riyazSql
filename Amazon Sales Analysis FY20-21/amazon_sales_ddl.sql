create table dim_categories (
category_id		int primary key,
category_name	varchar(50)
)


create table dim_products (
product_id			bigint primary key,
product_sku			varchar(500),
price				float,
discount_percent	float,
category_id 		int,
constraint fk_dim_products_dim_categories foreign key(category_id) references dim_categories(category_id)
)


create table dim_customers (
customer_id		bigint primary key,
first_name		varchar(50),
last_name		varchar(50),
gender			varchar(10),
age				int,
e_mail			varchar(50),
sign_in_date	date,
phone_no		varchar(50),
country			varchar(50),
city			varchar(50),
state			varchar(10),
zip_code		varchar(50),
region			varchar(50)
)


create table dim_order_items (
order_item_id	bigint primary key,
order_id		bigint,
product_id		bigint,
qty_ordered		int,
price			float,
constraint fk_dim_order_items_dim_products foreign key(product_id) references dim_products(product_id)
)


create table fact_orders (
order_id			bigint,	
order_item_id		bigint,
customer_id			bigint,
product_id			bigint,
order_date			date,
order_status		varchar(50),
payment_method		varchar(50),
constraint fk_fact_orders_dim_order_items foreign key(order_item_id) references dim_order_items(order_item_id),
constraint fk_fact_orders_dim_customers foreign key(customer_id) references dim_customers(customer_id),
constraint fk_fact_orders_dim_products foreign key(product_id) references dim_products(product_id)
)

