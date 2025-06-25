#product wise sales 
select p.product_id,p.product_name,sum(s.quantity) as quantity_sold
from products as p
join sales as s 
on p.product_id = s.product_id
group by 1,2
order by 3 desc;

#store wise sales 
select st.store_id,st.store_name,sum(sa.quantity) as quantity_sold
from stores as st
join sales as sa 
on sa.store_id = sa.store_id
group by 1,2
order by 3 desc;

select st.country,sum(sa.quantity)
from stores as st
join sales as sa
on st.store_id = sa.store_id
group by 1
order by 2 desc;

select * from warranty;
1.Find the number of stores in each country.
select country,count(store_id)
from stores
group by 1
order by 2 desc;

2.Calculate the total number of units sold by each store.
select 
st.store_id,st.store_name,sum(sa.quantity) as quantity_sold
from sales as sa
join stores as st
on st.store_id = sa.store_id
group by 1,2
order by 3 desc;


3.Identify how many sales occurred in December 2023.
select count(*) as total_sales
from sales
where (extract(month from sale_date )) = 12
and (extract(year from sale_date )) = 2023;

4.Determine how many stores have never had a warranty claim filed.
select count(*) from stores 
where store_id not in 
(
					select distinct s.store_id
					from sales as s
					right join warranty as w
					on w.sale_id = s.sale_id
);

5.Calculate the percentage of warranty claims marked as "Warranty Void".
select 
round(count(claim_id)/
				(select count(*) from warranty)::numeric * 100,2) as percentage
from warranty
where repair_status = 'Warranty Void';

6.Identify which store had the highest total units sold in the last year.
select store_id,sum(quantity)
from sales
where sale_date >= (CURRENT_DATE - INTERVAL '1 year')
group by 1
order by 2 desc;

7.Count the number of unique products sold in the last year.
select 
count(distinct product_id)
from sales
where sale_date >= (CURRENT_DATE - INTERVAL '1 year');

8.Find the average price of products in each category.
select pr.category_id,ca.category_name,avg(pr.price)
from products as pr
join category as ca
on pr.category_id = ca.category_id
group by 1,2
order by 3 desc;

9.How many warranty claims were filed in 2020
select count(*)
from warranty as wa
where extract(year from claim_date) = 2020;

10.Identify the best-selling day for each store.
with cte as 
(	select st.store_id,
	st.store_name,
	To_CHAR(sa.sale_date,'Day') as sale_day_name,
	sum(quantity) as quantity_sold,
	ROW_NUMBER() OVER (PARTITION BY st.store_id ORDER BY sum(quantity) desc) AS rank
	from sales as sa
	join stores as st
	on sa.store_id = st.store_id
	group by 1,2,3
)
select * from cte
where rank =1;

11.Identify the least selling product in each country for each year.
with cte as (
				select 
				pr.product_id,
				pr.product_name,
				st.country,
				extract(year from sa.sale_date) as sale_year,
				sum(sa.quantity),
				ROW_NUMBER() OVER (PARTITION BY st.country,	extract(year from sa.sale_date) ORDER BY sum(sa.quantity) asc) AS rank
				from products as pr
				join sales as sa
				on sa.product_id = pr.product_id
				join stores as st
				on st.store_id = sa.store_id
				group by 1,2,3,4
	)
select * from cte
where rank = 1
;

12.Calculate how many warranty claims were filed within 180 days of a product sale.
select count(*)
from warranty as w
left join sales as sa
on sa.sale_id = w.sale_id
where 
claim_date - sale_date <=180;

13.Determine how many warranty claims were filed for products launched in the last two years.
select p.product_name,
count(w.claim_id) as no_of_claim,
count(s.sale_id) as total_sales
from warranty as w
right join sales as s
on s.sale_id = w.sale_id
join products as p
on p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
group by 1;

14.List the months in the last three years where sales exceeded 5,000 units in the USA.
select
TO_CHAR(sa.sale_date,'MM-YYYY'),
sum(sa.quantity)
from sales as sa
join stores as st
on st.store_id = sa.store_id
where country = 'USA'
and sa.sale_date >= CURRENT_DATE - INTERVAL '3 years'
group by 1
having sum(sa.quantity) > 5000
;

15.Identify the product category with the most warranty claims filed in the last two years.
select ca.category_name,count(w.claim_id)
from warranty as w
left join sales as sa
on w.sale_id = sa.sale_id
join products as pr
on pr.product_id = sa.product_id
join category as ca
on ca.category_id = pr.category_id
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '2 years'
group by 1
order by 2 desc;

16.Determine the percentage chance of receiving warranty claims after each purchase for each country.
with cte as
(	select st.country, sum(s.quantity) as Total_unit_sold,count(w.claim_id) as total_claim
	from sales as s
	join stores as st
	on st.store_id = s.store_id
	left join warranty as w
	on w.sale_id = s.sale_id
	group by 1
)
select country,Total_unit_sold,total_claim,
round(COALESCE(total_claim ::numeric/Total_unit_sold ::numeric *100,0),2) as risk
from cte
order by 4 desc;

17.Analyze the year-by-year growth ratio for each store.
WITH cte AS (
    SELECT 
        st.store_name AS st_name,
        EXTRACT(YEAR FROM sale_date) AS year,
        SUM(s.quantity * pr.price) AS Total_sales
    FROM sales AS s
    JOIN products AS pr ON pr.product_id = s.product_id
    JOIN stores AS st ON st.store_id = s.store_id
    GROUP BY 1, 2
)
SELECT 
    st_name,
    year,
    Total_sales,
    LAG(Total_sales) OVER (PARTITION BY st_name ORDER BY year) AS previous_quantity_sold,
    ROUND(
        (
            (Total_sales - LAG(Total_sales) OVER (PARTITION BY st_name ORDER BY year)) * 100.0 / 
            NULLIF(LAG(Total_sales) OVER (PARTITION BY st_name ORDER BY year), 0)
        )::numeric, 2
    ) AS percentage_change
FROM cte;

18.Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.
select
case
when p.price< 500 then 'Less Expensive Product'
when p.price between 500 and 1000 then 'Mid Range Product'
else 'Expensive Product'
end as price_segment,
count(w.claim_id) as total_claim
from warranty as w
left join sales as s
on s.sale_id = w.sale_id
join products as p
on s.product_id = p.product_id
where w.claim_date >= current_date - interval '5 year'
group by 1;

19.Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.
WITH cte AS (
    SELECT 
        st.store_id,
        st.store_name,
        COUNT(w.claim_id) AS total_claims,
        SUM(CASE WHEN w.repair_status = 'Paid Repaired' THEN 1 ELSE 0 END) AS paid_repaired_claims
    FROM warranty AS w
    JOIN sales AS s ON s.sale_id = w.sale_id
    JOIN stores AS st ON st.store_id = s.store_id
    GROUP BY st.store_id, st.store_name
)
SELECT 
    store_id,
    store_name,
    total_claims,
    paid_repaired_claims,
    ROUND((paid_repaired_claims * 100.0) / NULLIF(total_claims, 0), 2) AS percentage_paid_repaired
FROM cte
ORDER BY percentage_paid_repaired DESC;

20.Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends.
with cte as
(
select store_id,
extract(year from sale_date) as year,
extract(month from sale_date) as month,
sum(p.price*s.quantity) as total_revenue
from sales as s
join products as p
on p.product_id = s.product_id
group by 1,2,3
order by 1,2,3
)
select store_id,month,year,total_revenue,
sum(total_revenue) over (partition by store_id order by year,month) as running_total
from cte;

21.Analyze product sales trend over time,segmented into key periods:from launch to 6 months,6-12 months,12-18 months and beyond 18 months.
select p.product_name,
case
when s.sale_date between p.launch_date and p.launch_date + interval '6 month' then '0-6 months'
when s.sale_date between p.launch_date + interval '6 month' and p.launch_date + interval '12 month' then '6-12 months'
when s.sale_date between p.launch_date + interval '12 month' and p.launch_date + interval '18 month' then '12-18 months'
else 'beyond 18 months'
end as plc,
sum(s.quantity) as total_quantity_sold
from sales as s
join products as p
on p.product_id = s.product_id 
group by 1,2
order by 1,3;


