set schema 'dwh';

select dp.name, sum(dp.quantity) as total_quantity
from fact_turnover ft
         join dim_product dp on dp.id = ft.product_id
         join dim_time dt on dt.id = ft.time_id
         join dim_customer dc on dc.id = ft.customer_id
where dt.month = 12
group by dp.name
order by total_quantity desc
limit 5;

select dp.name, dt.month, dc.country, sum(ft.turnover) as total_turnover
from fact_turnover ft
         join dim_product dp on dp.id = ft.product_id
         join dim_time dt on dt.id = ft.time_id
         join dim_customer dc on dc.id = ft.customer_id
group by cube (dp.name, dt.month, dc.country)