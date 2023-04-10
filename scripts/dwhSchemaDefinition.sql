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
    id          int primary key generated always as identity, -- künstlicher Primärschlüssel um Duplikate zu vermeiden
    product_id  int  not null,                                -- Primärschlüssel des Produktes aus der Quelle
    name        text not null,                                -- Name des Produktes
    order_id    int  not null,                                -- Primärschlüssel der Bestellung aus der Quelle
    supplier_id int  not null,                                -- Primärschlüssel des Lieferanten aus der Quelle
    supplier    text not null,                                -- Name des Lieferanten
    city        text not null,                                -- Adresse des Lieferanten
    country     text not null,
    quantity    int  not null,                                -- Anzahl der Produkte in der Bestellung
    category_id int  not null,                                -- Primärschlüssel der Kategorie aus der Quelle
    category    text not null                                 -- Name der Kategorie
);

-- dimension
create table dim_customer (
    id          int primary key generated always as identity,
    customer_id int  not null, -- Primärschlüssel des Kunden aus der Quelle
    name        text not null, -- Name des Kunden
    city        text not null, -- Adresse des Kunden
    country     text not null
);

-- dimension
create table dim_personnel (
    id           int primary key generated always as identity,
    personnel_id int  not null, -- Primärschlüssel des Mitarbeiters aus der Quelle
    last_name    text not null, -- Nachname des Mitarbeiters
    first_name   text not null  -- Vorname des Mitarbeiters
);

-- dimension
create table dim_shipper (
    id         int primary key generated always as identity,
    shipper_id int  not null, -- Primärschlüssel des Lieferanten aus der Quelle
    name       text not null  -- Name des Lieferanten
);

-- dimension
create table dim_time (
    id      int primary key generated always as identity,
    month   int not null check ( month >= 1 and month <= 12 ),   -- Monat, check um sicherzustellen, dass der Monat zwischen 1 und 12 liegt
    quarter int not null check (quarter >= 1 and quarter <= 4 ), -- Quartal, check um sicherzustellen, dass das Quartal zwischen 1 und 4 liegt
    year    int not null
);

-- fact
create table if not exists fact_turnover (
    id           int primary key generated always as identity,
    product_id   int            not null references dim_product (id),
    customer_id  int            not null references dim_customer (id),
    personnel_id int            not null references dim_personnel (id),
    shipper_id   int            not null references dim_shipper (id),
    time_id      int            not null references dim_time (id), -- Primärschlüssel der Zeitdimension; Angabe des Bestelldatums
    turnover     numeric(15, 2) not null                           -- Umsatz, 15 Stellen vor dem Komma, 2 Stellen nach dem Komma (Anzahl der Produkte * Einzelpreis) - Rabatt
);

-- fact
create table if not exists fact_freight_cost (
    id           int primary key generated always as identity,
    order_id     int            not null,
    customer_id  int            not null references dim_customer (id),
    personnel_id int            not null references dim_personnel (id),
    shipper_id   int            not null references dim_shipper (id),
    time_id      int            not null references dim_time (id), -- Primärschlüssel der Zeitdimension; Angabe des Versanddatums
    freight_cost numeric(15, 2) not null                           -- Frachtkosten, 15 Stellen vor dem Komma, 2 Stellen nach dem Komma
);