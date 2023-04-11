set schema 'dwh';

-- a.   Welche fünf Produkte wurden in dem Monat “Dezember” am meisten verkauft?
select prod.name as product_name, sum(prod.quantity) as total_quantity
from fact_turnover turn
         join dim_product prod on prod.id = turn.product_id
         join dim_time time on time.id = turn.time_id
         join dim_customer cust on cust.id = turn.customer_id
where time.month = 12
group by prod.name
order by total_quantity desc
limit 5;

-- b.   Wie viel Umsatz wurde, gruppiert nach Produkt Name, Monat und Land gemacht?
select prod.name, time.month, cust.country, sum(turn.turnover) as total_turnover
from fact_turnover turn
         join dim_product prod on prod.id = turn.product_id
         join dim_time time on time.id = turn.time_id
         join dim_customer cust on cust.id = turn.customer_id
group by cube (prod.name, time.month, cust.country);

-- c.   Wie viel Umsatz wurde pro Kategorie und Monat gemacht?
select prod.category, time.month, sum(turn.turnover) as total_turnover
from fact_turnover turn
         join dim_product prod on prod.id = turn.product_id
         join dim_time time on time.id = turn.time_id
group by rollup (prod.category, time.month);

-- d.   Wie viel Umsatz wurde in der Kategorie „toys“ gruppiert nach Monat und Land gemacht.
select prod.name as product_name, time.month, cust.country, sum(turn.turnover) as total_turnover
from fact_turnover turn
         join dim_product prod on prod.id = turn.product_id
         join dim_time time on time.id = turn.time_id
         join dim_customer cust on turn.customer_id = cust.id
where prod.category = 'toys'
group by cube (prod.name, time.month, cust.country);

-- e.	Wie viele Frachtkosten fallen pro Versandfirma und Land an?
select ship.name as shipper_name, cust.country, sum(freight.freight_cost) as total_cost
from fact_freight_cost freight
         join dim_time time on time.id = freight.time_id
         join dim_customer cust on cust.id = freight.customer_id
         join dim_shipper ship on freight.shipper_id = ship.id
group by rollup (ship.name, cust.country);

---f.   Welche Kategorie hat welcher Mitarbeiter am meisten verkauft?
select distinct (first_value(category) over (partition by category),
                 first_value(pers_last_name) over (partition by category))  as category_per_personnel_max,
                max(quant) over (partition by category) as max_quantity
from (select prod.category as category, pers.last_name as pers_last_name, sum(prod.quantity) as quant
      from fact_turnover turn
               inner join dim_product prod on prod.product_id = turn.product_id
               inner join dim_personnel pers on pers.personnel_id = turn.personnel_id
      group by category, pers_last_name)
as t;
