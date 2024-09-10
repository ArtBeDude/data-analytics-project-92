/* Quer to determine the number of clients
* customer_count
*/
select count(customer_id) as customers_count
from customers

--------------------------------------------------------------

/* Query to find the top 10 sellers with the highest amounts
sales
* top_10_total_income
*/

with tab1 as (                                      
select
	concat(e.first_name,' ',e.last_name) as seller,
	p.product_id,
	s.quantity,
	p.price
from sales s
left join
	employees e 
	on s.sales_person_id = e.employee_id 
left join
	products p 
	on s.product_id = p.product_id
),
/* In the subquery "tab1" we join the tables according to their id references.
 * Select the required columns, merge the columns "e.first_name" and "e.last_name" from
 * "employees" tables
*/
select
	distinct seller, -- Choose only unique sellers
	count(*) 
		over (partition by seller) as operations, 
	floor(sum(quantity * price) 
		over (partition by seller)) as income 
from tab1
order by income desc
limit 10

--------------------------------------------------------------	

with tab1 as (
select 
	concat(e.first_name,' ',e.last_name) as seller,
	p.product_id,
	s.quantity,
	p.price
from sales s
left join 
	employees e 
	on s.sales_person_id = e.employee_id 
left join 
	products p 
	on s.product_id = p.product_id
),
tab2 as (
select
	 distinct seller, 
	floor(AVG(quantity * price) 
		over (partition by seller)) as average_income, 
	AVG(quantity * price) 
		over () as avg_total 
from tab1
)
select
	seller,
	average_income as average_income 
from tab2
group by 1,2
having average_income < AVG(avg_total)
order by average_income	
	
--------------------------------------------------------------

with tab1 as (
select 
	concat(e.first_name,' ',e.last_name) as seller,
	p.product_id,
	s.quantity,
	p.price,
	(EXTRACT(ISODOW FROM s.sale_date) - 1) as num_of_day, 
	to_char(s.sale_date, 'Day') as day_of_week 
from sales s
left join 
	employees e 
	on s.sales_person_id = e.employee_id 
left join 
	products p 
	on s.product_id = p.product_id
),
tab2 as (
select
	distinct seller,
	day_of_week,
	sum(price * quantity)
		over (partition by seller, day_of_week) as income,
	num_of_day
from tab1
order by num_of_day, seller
)
select
	seller,
	day_of_week,
	floor(income) as income
from tab2

--------------------------------------------------------------

with tab1 as ()
select 
	*,
	case -- 
		when age between 16 and 25 then '16-25'
		when age between 26 and 40 then '26-40'
		when age > 40 then '40+'
	end as age_category
from customers c 
)
select 
	distinct age_category,
	count(age) over (partition by age_category) as age_count 
from tab1
order by age_category;

--------------------------------------------------------------

with tab1 as ( 
select	       
	to_char(s.sale_date, 'YYYY-MM') as selling_month,
	concat(c.first_name,' ',c.last_name) as customer_name
from sales s
left join 
	customers c 
	on s.customer_id = c.customer_id
),
tab2 as (     
select distinct customer_name,
selling_month
from tab1
),
tab3 as (     
select	      
	distinct selling_month,
	count(customer_name)
		over (partition by selling_month)
from tab2
),
tab4 as (     
select        
	to_char(s.sale_date, 'YYYY-MM') as selling_month,
	p.product_id,
	s.quantity,
	p.price
from sales s
left join 
	products p 
	on s.product_id = p.product_id
)
select	     
	distinct tab4.selling_month,
	tab3.count as total_customers,
	floor(sum(tab4.price*tab4.quantity) 
		over (partition by tab4.selling_month)) as income
from tab4
inner join tab3
on tab4.selling_month = tab3.selling_month

--------------------------------------------------------------

with tab1 as (
select		   
	s.customer_id,
	concat(c.first_name,' ',c.last_name) as customer, 
	sale_date,
	concat(e.first_name,' ',e.last_name) as seller,
	p.price,
	row_number () 
		over (partition by concat(c.first_name,' ',c.last_name),  
			concat(e.first_name,' ',e.last_name) 
			order by sale_date) as flag_1,
	row_number () 
		over (partition by concat(c.first_name,' ',c.last_name)) as flag_2 
from sales s
left join 
	customers c
	on s.customer_id = c.customer_id 
left join 
	employees e
	on s.sales_person_id = e.employee_id 
left join 
	products p 
	on s.product_id = p.product_id
where price = 0 
)
select
	customer,
	sale_date,
	seller
from tab1 
where flag_1 = 1 and flag_2 = 1
order by customer_id;
