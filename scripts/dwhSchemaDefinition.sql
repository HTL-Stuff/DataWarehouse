create schema if not exists dwh;
set schema 'dwh';

drop table if exists fact_turnover;
drop table if exists fact_freight_cost;
drop table if exists dim_product;
drop table if exists dim_customer;
drop table if exists dim_personnel;
drop table if exists dim_shipper;
drop table if exists dim_time;

-- dimension
create table dim_product (
    id int primary key generated always as identity,
    name text not null,
    supplier text not null,
    city text not null,
    country text not null,
    quantity int not null,
    category text not null,
    total int not null
);

-- dimension
create table dim_customer (
    id int primary key generated always as identity,
    name text not null,
    city text not null,
    country text not null,
    total int not null
);

-- dimension
create table dim_personnel (
    id int primary key generated always as identity,
    name text not null,
    total int not null
);

-- dimension
create table dim_shipper (
    id int primary key generated always as identity,
    name text not null,
    total int not null
);

-- dimension
create table dim_time (
    id int primary key generated always as identity,
    month_name text not null,
    month int not null,
    year int not null,
    season text not null
);

-- fact
create table if not exists fact_turnover (
    id int primary key generated always as identity,
    product_id int not null references dim_product(id),
    customer_id int not null references dim_customer(id),
    personnel_id int not null references dim_personnel(id),
    shipper_id int not null references dim_shipper(id),
    time_id int not null references dim_time(id)
);

-- fact
create table if not exists fact_freight_cost (
    id int primary key generated always as identity,
    customer_id int not null references dim_customer(id),
    personnel_id int not null references dim_personnel(id),
    shipper_id int not null references dim_shipper(id),
    time_id int not null references dim_time(id)
);