SET schema 'oltp';

drop table if exists "order";
drop table if exists shipper;
drop table if exists personnel;
drop table if exists customer;
drop table if exists product;
drop table if exists category;
drop table if exists supplier;

create table if not exists supplier(
    supplier_id    int primary key,
    company_name   text not null,
    contact_person text not null,
    "position"       text not null,
    address        text not null,
    city           text not null,
    region         text not null,
    postal_code    text not null,
    country        text not null,
    phone          text,
    fax            text
);

create table if not exists category(
    category_id int primary key,
    category_name text not null,
    description text not null
);

create table if not exists product(
    product_id  int primary key,
    supplier_id int not null references supplier (supplier_id),
    category_id int not null references category (category_id),
    product text not null,
    unit text not null,
    unit_price int not null,
    stock_quantity int not null,
    stock_unit text not null,
    minimum_quantity int not null,
    discontinued boolean not null default false
);

create table if not exists customer(
    customer_id int primary key,
    company_name text not null,
    contact_person text not null,
    "position" text not null,
    address text not null,
    city text not null,
    region text not null,
    postal_code text not null,
    country text not null,
    phone text,
    fax text
);

create table if not exists personnel (
    personnel_id int primary key,
    last_name text not null,
    first_name text not null,
    "position" text not null,
    date_of_birth date,
    hire_date date,
    address text not null,
    city text not null,
    region text not null,
    postal_code text not null,
    country text not null,
    phone text,
    phone_work text,
    "comment" text,
    supervisor_id int references personnel (personnel_id)
);

create table if not exists shipper(
    shipper_id int primary key,
    company_name text not null
);

create table if not exists "order"(
    order_id int primary key,
    customer_id int not null references customer (customer_id),
    personnel_id int not null references personnel (personnel_id),
    receiver text not null,
    address text not null,
    city text not null,
    region text not null,
    postal_code text not null,
    country text not null,
    shipper_id int not null references shipper (shipper_id),
    order_date date not null,
    required_date date not null,
    shipped_date date not null,
    freight_cost int not null
);