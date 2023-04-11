set schema 'dwh';
-- The following function is used to create a date key from a date string. The function will return the primary key for the date in the table. If the date key does not exist in the dimension table, it will be created.
create or replace function dwh.get_date_key(date_string text) returns integer as
$$
declare
    date_key      integer;
    date_parts    text[];
    param_year    integer;
    param_quarter integer;
    param_month   integer;
begin
    -- get the date parts from the string
    date_parts := string_to_array(date_string, '-');
    param_year := date_parts[1]::integer;
    param_quarter := (date_parts[2]::integer - 1) / 3 + 1;
    param_month := date_parts[2]::integer;

    -- check if the date is already present in the table, if not insert it
    select id
    into date_key
    from dwh.dim_time
    where year = param_year and quarter = param_quarter and month = param_month;
    if date_key is null then
        insert into dwh.dim_time (year, quarter, month)
        values (param_year, param_quarter, param_month)
        returning id into date_key;
    end if;
    return date_key::integer;
end;
$$ language plpgsql;

-- insert the product itself to the table
create or replace function dwh.get_product_key(
    param_product_id integer,
    param_name text,
    param_order_id integer,
    param_city text,
    param_quantity integer,
    param_country text,
    param_supplier_id integer,
    param_supplier text,
    param_category text,
    param_category_id integer
) returns integer as
$$
declare
    product_key integer;
begin
    -- check if the customer already exists in the dimension table, if not insert it
    select id
    into product_key
    from dwh.dim_product p
    where p.product_id = param_product_id
      and p.name = param_name
      and p.order_id = param_order_id
      and p.city = param_city
      and p.quantity = param_quantity
      and p.country = param_country
      and p.supplier_id = param_supplier_id
      and p.supplier = param_supplier
      and p.category = param_category
      and p.category_id = param_category_id;

    if product_key is null then
        insert into dwh.dim_product (product_id, name, order_id, city, quantity, country, supplier_id, supplier, category, category_id)
        values (param_product_id, param_name, param_order_id, param_city, param_quantity, param_country, param_supplier_id, param_supplier, param_category, param_category_id)
        returning id into product_key;
    end if;

    return product_key::integer;
end;
$$ language plpgsql;

-- check if the customer already exists in the dimension table, if not insert it
create or replace function dwh.get_customer_key(
    param_customer_id integer,
    param_name text,
    param_city text,
    param_country text
) returns integer as
$$
declare
    customer_key integer;
begin
    select id
    into customer_key
    from dwh.dim_customer c
    where c.customer_id = param_customer_id
      and c.name = param_name
      and c.city = param_city
      and c.country = param_country;

    if customer_key is null then
        insert into dwh.dim_customer (customer_id, name, city, country)
        values (param_customer_id, param_name, param_city, param_country)
        returning id into customer_key;
    end if;

    return customer_key::integer;
end;
$$ language plpgsql;

-- check if the personnel already exists in the dimension table, if not insert it
create or replace function dwh.get_personnel_key(
    param_personnel_id integer,
    param_first_name text,
    param_last_name text
) returns integer as
$$
declare
    personnel_key integer;
begin
    select id
    into personnel_key
    from dwh.dim_personnel p
    where p.personnel_id = param_personnel_id
      and p.first_name = param_first_name
      and p.last_name = param_last_name;

    if personnel_key is null then
        insert into dwh.dim_personnel (personnel_id, first_name, last_name)
        values (param_personnel_id, param_first_name, param_last_name)
        returning id into personnel_key;
    end if;

    return personnel_key::integer;
end;
$$ language plpgsql;

-- check if the shipper already exists in the dimension table, if not insert it
create or replace function dwh.get_shipper_key(
    param_shipper_id integer,
    param_name text
) returns integer as
$$
declare
    shipper_key integer;
begin
    select id into shipper_key from dwh.dim_shipper s where s.shipper_id = param_shipper_id and s.name = param_name;

    if shipper_key is null then
        insert into dwh.dim_shipper (shipper_id, name)
        values (param_shipper_id, param_name)
        returning id into shipper_key;
    end if;

    return shipper_key::integer;
end;
$$ language plpgsql;

-- insert the freight cost to the fact table
create or replace function dwh.insert_fact_freight_cost(
    param_date_key integer,
    param_order_id integer,
    param_customer_key integer,
    param_personnel_key integer,
    param_shipper_key integer,
    param_freight_cost numeric
) returns void as
$$
declare
    count integer;
begin
    select count(id)
    into count
    from dwh.fact_freight_cost f
    where f.order_id = param_order_id
      and f.customer_id = param_customer_key
      and f.personnel_id = param_personnel_key
      and f.shipper_id = param_shipper_key
      and f.freight_cost = param_freight_cost;
    if count = 0 then
        insert into dwh.fact_freight_cost (order_id, customer_id, personnel_id, shipper_id, time_id, freight_cost)
        values (param_order_id, param_customer_key, param_personnel_key, param_shipper_key, param_date_key, param_freight_cost);
    end if;
end;
$$ language plpgsql;

-- The following function is used to load the sales data into the fact table. The function will first load the dimension tables and then the fact table.
create or replace function dwh.load_dwh() returns void as
$$
declare
    cursor        refcursor;
    temp_table    record;
    date_key      integer;
    product_key   integer;
    customer_key  integer;
    personnel_key integer;
    shipper_key   integer;
begin

    -- fetch the data from the OLTP database
    open cursor for select od.order_id,
                           od.product_id,
                           od.price_per_unit,
                           od.quantity,
                           od.discount,
                           o.order_date,
                           o.shipped_date,
                           o.freight_cost,
                           cs.customer_id,
                           cs.company_name as customer_name,
                           cs.city         as customer_city,
                           cs.country      as customer_country,
                           pe.personnel_id,
                           pe.first_name,
                           pe.last_name,
                           si.shipper_id,
                           si.company_name as shipper_name,
                           p.product,
                           c.category_id,
                           c.category_name,
                           s.supplier_id,
                           s.company_name,
                           s.city,
                           s.country
                    from oltp.order_details od
                             join oltp."order" o on o.order_id = od.order_id
                             join oltp.product p on p.product_id = od.product_id
                             join oltp.category c on c.category_id = p.category_id
                             join oltp.supplier s on s.supplier_id = p.supplier_id
                             join oltp.customer cs on o.customer_id = cs.customer_id
                             join oltp.personnel pe on pe.personnel_id = o.personnel_id
                             join oltp.shipper si on o.shipper_id = si.shipper_id;

    loop
        fetch cursor into temp_table;
        exit when not found;
        -- get the surrogate keys for the dimension tables, if they do not exist, they will be created
        product_key := (select dwh.get_product_key(temp_table.product_id, temp_table.product, temp_table.order_id,
                                                   temp_table.city, temp_table.quantity, temp_table.country,
                                                   temp_table.supplier_id, temp_table.company_name,
                                                   temp_table.category_name, temp_table.category_id));
        customer_key :=
                (select dwh.get_customer_key(temp_table.customer_id, temp_table.customer_name, temp_table.customer_city,
                                             temp_table.customer_country));
        personnel_key :=
                (select dwh.get_personnel_key(temp_table.personnel_id, temp_table.first_name, temp_table.last_name));
        shipper_key := (select dwh.get_shipper_key(temp_table.shipper_id, temp_table.shipper_name));
        date_key := (select dwh.get_date_key(temp_table.order_date::text));

        -- insert the fact table, could also be done with a dedicated function
        insert into dwh.fact_turnover(product_id, customer_id, personnel_id, shipper_id, time_id, turnover)
        VALUES (product_key, customer_key, personnel_key, shipper_key, date_key, temp_table.price_per_unit *
                                                                                 temp_table.quantity *
                                                                                 (1 - (temp_table.discount / 100)))
        on conflict do nothing;
        -- update date key to shipped date
        date_key := (select dwh.get_date_key(temp_table.shipped_date::text));
        -- insert the freight cost to the fact table, i chose to use a function for this because we need to check if the freight cost already exists. Since multiple order_ids can be present, if more products are ordered.
        perform dwh.insert_fact_freight_cost(date_key, temp_table.order_id, customer_key, personnel_key, shipper_key,
                                             temp_table.freight_cost);
    end loop;
end;
$$ language plpgsql;

truncate table dim_product cascade;
truncate table dim_customer cascade;
truncate table dim_personnel cascade;
truncate table dim_shipper cascade;
truncate table dim_time cascade;
truncate table fact_freight_cost cascade;
truncate table fact_turnover cascade;
select load_dwh();

drop function load_dwh();