/*--------------------------------- INDEXING FOR QUERY OPTIMIZATION ---------------------------------*/

-- Indexing dim_categories table.

create index index_categories_categoryID on dim_categories(category_id); 
cluster dim_categories using index_categories_categoryID;

-- Indexing dim_products table.

create index index_products_productID on dim_products(product_id); 
cluster dim_products using index_products_productID;
create index index_products_categoryID on dim_products(category_id); 
create index index_products_price on dim_products(price); 

-- Indexing fact_orders table.

create index index_orders_orderID on fact_orders(order_id); 
cluster fact_orders using index_orders_orderID;
create index index_orders_customerID on fact_orders(customer_id); 
create index index_orders_orderDate on fact_orders(order_date);

-- Indexing dim_order_items table.

create index index_orderItems_orderItemID on dim_order_items(order_item_id); 
cluster dim_order_items using index_orderItems_orderItemID;
create index index_orderItems_orderID on dim_order_items(order_id); 
create index index_orderItems_productID on dim_order_items(product_id);

-- Indexing dim_customers table.

create index index_customers_customerID on dim_customers(customer_id); 
cluster dim_customers using index_customers_customerID;
create index index_customers_country on dim_customers(country); 
create index index_customers_email on dim_customers(e_mail);













