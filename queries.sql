/* Запрос на поиск количества клиентов из таблицы */
select
	count(customer_id) as customers_count
from customers
/* Вычисление количества клиентов из таблицы "сustomers"*/

	
/* Запрос на поиск топ 10 продавцов с самыми большими суммами
продаж.*/
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


