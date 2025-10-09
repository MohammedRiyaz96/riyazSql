------------------------------------------- LOG MAINTENANCE FOR DML OPERATIONS ----------------------------------------------

------------------------------------------------- TABLE DEFINITION ----------------------------------------------------------

create table changeLog (
log_id			int primary key generated always as identity,
table_name		varchar(50),
operation		varchar(50),
record_id		int,
change_date		timestamp default now(),
changed_by		varchar(50)
);

----------------------------- CREATING TRIGGERS TO LOG INSERT, UPDATE AND DELETE OPERATIONS ---------------------------------

-- Trigger for INSERT on dim_products table.

create function ins_products_func ()
returns trigger
language 'plpgsql'
as $$
declare
begin
	insert into changeLog (table_name, operation, record_id, changed_by)
	values('dim_products', 'INSERT', new.product_id, system_user);
return new;
end;
$$;

create trigger trigger_products_insert
after insert
on dim_products
for each row
execute function ins_products_func();

insert into dim_products values(100001, 'Convertible dining sofa', 8900, 0, 5);
insert into dim_products values(100002, 'Recliner sofa', 6500, 0, 5);
insert into dim_products values(100003, 'King size bedsheet 8*8', 1000, 0, 5);
insert into dim_products values(100004, 'Queen size bedsheet 7*7', 900, 0, 5);


-- Trigger for UPDATE on dim_products table.

create function upd_products_func ()
returns trigger
language 'plpgsql'
as $$
declare
begin
	insert into changeLog (table_name, operation, record_id, changed_by)
	values('dim_products', 'UPDATE', new.product_id, system_user);
return new;
end;
$$;

create trigger trigger_products_update
after update
on dim_products
for each row
execute function upd_products_func();

update dim_products set price = 7200 where product_id = 100002;
select * from changeLog


-- Trigger for DELETE on dim_products table.

create function del_products_func ()
returns trigger
language 'plpgsql'
as $$
declare
begin
	insert into changeLog (table_name, operation, record_id, changed_by)
	values('dim_products', 'DELETE', old.product_id, system_user);
return new;
end;
$$;

create trigger trigger_products_delete
after delete
on dim_products
for each row
execute function del_products_func();

select * from dim_products where product_id = 100002
delete from dim_products where product_id = 100002;
delete from dim_products where product_id = 100004;
select * from changeLog


-- Trigger for INSERT on dim_customers table.

create function ins_customers_func ()
returns trigger
language 'plpgsql'
as $$
declare
begin
	insert into changeLog (table_name, operation, record_id, changed_by)
	values('dim_customers', 'INSERT', new.customer_id, system_user);
return new;
end;
$$;

create trigger trigger_customers_insert
after insert
on dim_customers
for each row
execute function ins_customers_func();

insert into dim_customers values (221290, 'Donna', 'Paulsen', 'F', 36, 'donpaul@suits.com', 
to_date('1997-04-12', 'yyyy-mm-dd'), '124-787-3545', 'United States', 'New york', 'NY', '10012', 'Northeast');
select * from changeLog


-- Trigger for UPDATE on dim_customers table.

create function upd_customers_func ()
returns trigger
language 'plpgsql'
as $$
declare
begin
	insert into changeLog (table_name, operation, record_id, changed_by)
	values('dim_customers', 'UPDATE', new.customer_id, system_user);
return new;
end;
$$;

create trigger trigger_customers_update
after update
on dim_customers
for each row
execute function upd_customers_func();

update dim_customers set age = 29 where customer_id = 221289
select * from changeLog


-- Trigger for DELETE on dim_customers table.

create function del_customers_func ()
returns trigger
language 'plpgsql'
as $$
declare
begin
	insert into changeLog (table_name, operation, record_id, changed_by)
	values('dim_customers', 'DELETE', old.customer_id, system_user);
return new;
end;
$$;

create trigger trigger_customers_delete
after delete
on dim_customers
for each row
execute function del_customers_func();

delete from dim_customers where customer_id = 221290
select * from changeLog


