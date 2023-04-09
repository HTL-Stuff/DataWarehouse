create schema if not exists oltp;
set schema 'oltp';

drop table if exists order_details;
drop table if exists "order";
drop table if exists shipper;
drop table if exists personnel;
drop table if exists customer;
drop table if exists product;
drop table if exists category;
drop table if exists supplier;

create table if not exists supplier (
    supplier_id    int primary key,
    company_name   text not null,
    contact_person text not null, -- email der kontakt person
    "position"     text not null, -- position der kontakt person
    address        text not null,
    city           text not null,
    region         text not null,
    postal_code    text not null,
    country        text not null,
    phone          text,          -- telefonnummer der kontakt person
    fax            text           -- faxnummer der kontakt person
);

create table if not exists category (
    category_id   int primary key,
    category_name text not null,
    description   text not null
);

create table if not exists product (
    product_id       int primary key,
    supplier_id      int     not null references supplier (supplier_id), -- lieferant des produkts
    category_id      int     not null references category (category_id), -- kategorie des produkts
    product          text    not null,                                   -- name des produkts
    unit             text    not null,                                   -- einheit in der das produkt verkauft wird
    unit_price       int     not null,                                   -- preis pro einheit
    stock_quantity   int     not null,                                   -- anzahl der produkte auf lager
    stock_unit       text    not null,                                   -- einheit in der das produkt auf lager ist
    minimum_quantity int     not null,                                   -- minimale anzahl der produkte die auf lager sein müssen
    discontinued     boolean not null default false                      -- wenn kein wert angegeben wird, wird angenommen, dass das produkt nicht ausgemustert ist
);

create table if not exists customer (
    customer_id    int primary key,
    company_name   text not null,
    contact_person text not null, -- email der kontakt person
    "position"     text not null, -- position der kontakt person
    address        text not null,
    city           text not null,
    region         text not null,
    postal_code    text not null,
    country        text not null,
    phone          text,          -- telefonnummer der kontakt person
    fax            text           -- faxnummer der kontakt person
);

create table if not exists personnel (
    personnel_id  int primary key,
    last_name     text not null,
    first_name    text not null,
    "position"    text not null,                          -- position der person
    date_of_birth date,
    hire_date     date,
    address       text not null,
    city          text not null,
    region        text not null,
    postal_code   text not null,
    country       text not null,
    phone         text,
    phone_work    text,
    "comment"     text,
    supervisor_id int references personnel (personnel_id) -- id des übergeordneten personals
);

create table if not exists shipper (
    shipper_id   int primary key,
    company_name text not null -- name des lieferanten
);

create table if not exists "order" (
    order_id      int primary key,
    customer_id   int  not null references customer (customer_id),     -- id des kunden
    personnel_id  int  not null references personnel (personnel_id),   -- id des verantwortlichen personals
    receiver      text not null,                                       -- name des empfängers
    address       text not null,
    city          text not null,
    region        text not null,
    postal_code   text not null,
    country       text not null,
    shipper_id    int  not null references shipper (shipper_id),       -- id des lieferanten
    order_date    date not null,                                       -- datum der bestellung
    required_date date not null check ( required_date >= order_date ), -- datum bis wann die bestellung geliefert werden muss
    shipped_date  date not null check ( shipped_date >= order_date ),  -- datum an dem die bestellung geliefert wurde
    freight_cost  int  not null check ( freight_cost >= 0 )            -- kosten für die lieferung
);

create table if not exists order_details (
    order_id       int not null references "order" (order_id),                         -- id der bestellung
    product_id     int not null references product (product_id),                       -- id des produkts
    price_per_unit int not null check ( price_per_unit > 0 ),                          -- preis pro einheit
    count          int not null check ( count > 0 ),                                   -- anzahl der produkte
    discount       int not null default 0 check ( discount >= 0 and discount <= 100 ), -- rabatt in prozent
    primary key (order_id, product_id)                                                 -- der primary key besteht aus der kombination aus order_id und product_id
);