/* Запрос на поиск количества клиентов из таблицы
* customer_count
*/
select
	count(customer_id) as customers_count
from customers
/* Вычисление количества клиентов из таблицы "сustomers"*/

--------------------------------------------------------------
	
/* Запрос на поиск топ 10 продавцов с самыми большими суммами
продаж.
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
)
/* В подзапросе "tab1" мы соединяем таблицы согласно референсам их id.
 * Выбираем необходимые столбцы, объеденяем столбцы "e.first_name" и "e.last_name" из
 * таблицы "employees"
*/
select
	distinct seller, -- Выбор уникальных продавцов
	count(*) 
		over (partition by seller) as operations, -- Вычисление количества операций одного продавца
	floor(sum(quantity * price) 
		over (partition by seller)) as income -- Вычисление суммы продаж продавца и округление до целого
from tab1
order by income desc
limit 10
/* В итоговом запросе мы получили таблицу с 10-ю продавцами
   с самыми большими суммами продаж. */

--------------------------------------------------------------	

/* Запрос по поиску худших продавцов по средней сумме продаж
* lowest_average_income
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
/* В подзапросе "tab1" мы соединяем таблицы согласно референсам их id.
 * Выбираем необходимые столбцы, объеденяем столбцы "e.first_name" и "e.last_name" из
 * таблицы "employees"
 */
tab2 as (
select
	 distinct seller, -- оставляем только уникальные имена продавцов
	floor(AVG(quantity * price) 
		over (partition by seller)) as average_income, -- Вычисляем среднюю сумму продажи по продавцу
	AVG(quantity * price) 
		over () as avg_total -- Вычисляем среднюю сумму по всем продажам
from tab1
)
/* В подзапросе tab2 мы вычисляем значение средних продаж 
 * для последюущего их сравнения.
 */
select
	seller,
	average_income as average_income -- округляем значение до целого числа
from tab2
group by 1,2
having average_income < AVG(avg_total)
order by average_income	
	
--------------------------------------------------------------

/* Запрос по поиску продаж продавцов в разрезе дней недели.
 * day_of_week_income
 */
with tab1 as (
select 
	concat(e.first_name,' ',e.last_name) as seller,
	p.product_id,
	s.quantity,
	p.price,
	(EXTRACT(ISODOW FROM s.sale_date) - 1) as num_of_day, -- приводим нумерацию к Mon = 0
	to_char(s.sale_date, 'Day') as day_of_week -- выделяем название дня недели
from sales s
left join 
	employees e 
	on s.sales_person_id = e.employee_id 
left join 
	products p 
	on s.product_id = p.product_id
),
/* В подзапросе tab2 мы выводим уникальных продавцов и
 * считаем сумму продаж каждого продавца в партиции продавца и дня недели
 */ 

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

/* Итоговая витрина продаж в разрезе продавцов и дней
*/

--------------------------------------------------------------

/* Запрос по вычислению количества покупателей в разрезе
 * возрастных групп.
 * age_groups
*/
with tab1 as ()
select 
	*,
	case -- Присвоение категорий каждому диапазону возрастов
		when age between 16 and 25 then '16-25'
		when age between 26 and 40 then '26-40'
		when age > 40 then '40+'
	end as age_category
from customers c 
)
select 
	distinct age_category,
	count(age) over (partition by age_category) as age_count -- подсчёт количества покупателей в категории
from tab1
order by age_category;

--------------------------------------------------------------

/* В этом подзапросе мы вычисляем количество уникальных покупателей
 * и выручки в разрезе каждого месяца.
 * customers_by_month
 */
with tab1 as ( -- В подзапросе tab1 происходит приведение данных
select	       -- к необходимым типам.
	to_char(s.sale_date, 'YYYY-MM') as selling_month,
	concat(c.first_name,' ',c.last_name) as customer_name
from sales s
left join 
	customers c 
	on s.customer_id = c.customer_id
),
tab2 as (     -- В подзапросе tab2 мы находим уникальных покупателей в каждом месяце.
select distinct customer_name,
selling_month
from tab1
),
tab3 as (     -- В подзапросе tab3 мы находим количество уникальных покупателей
select	      -- в разрезе каждого месяца.
	distinct selling_month,
	count(customer_name)
		over (partition by selling_month)
from tab2
),
tab4 as (     -- tab4 представляет собой CTE с данными для подсчета суммарной выручки
select        -- в итоговом запросе.
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
	round(sum(tab4.price*tab4.quantity) 
		over (partition by tab4.selling_month)) as income
from tab4
inner join tab3
on tab4.selling_month = tab3.selling_month
/* В итоговом запросе мы соеденили CTE tab4 и tab3 по месяцам,
 * посчитали и округлили суммарную выручку по месяцам и указали количество уникальных клиентов
 * в каждом месяце
 */

--------------------------------------------------------------

/* В данном запросе мы нашли даты первых покупок в ходе
 * проведения акции
 * special_offer
 */

with tab1 as ( -- В этом подзапросе мы создаём общую таблицу со всеми данными
select		   -- необходимыми для нахождения искомых значений.
	s.customer_id,
	concat(c.first_name,' ',c.last_name) as customer,
	sale_date,
	concat(e.first_name,' ',e.last_name) as seller,
	p.price
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
order by sale_date -- Сортировка по дате asc для поиска будующих акционных покупок.
),
tab2 as ( -- В подзапросе tab2 мы нумируем все записи для поиска первой покупки.
select
	*,
	row_number () 
		over (partition by customer, sale_date, seller) as flag_1 
from tab1
),
tab3 as ( -- В этом подзапросе мы выбираем записи в которых первая покупка была в ходе
select	  -- проведения акции (price = 0).
	customer,
	sale_date,
 	seller,
 	row_number () 
		over (partition by customer, seller) as flag_2 -- Нумерация пары клиент - продавец.
from tab2
where flag_1 = 1 and price = 0
order by customer_id
)
select 	  -- Итоговый запрос отражающий искомые данные: клиента дату первой покупки - продавца.
	customer,
	sale_date,
	seller
from tab3
where flag_2 = 1 -- условие выбора первого дня акции для каждого клиента - продавца.




