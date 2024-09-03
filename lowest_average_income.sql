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
	AVG(quantity * price) 
		over (partition by seller) as average_income, -- Вычисляем среднюю сумму продажи по продавцу
	AVG(quantity * price) 
		over () as avg_total -- Вычисляем среднюю сумму по всем продажам
from tab1
)
/* В подзапросе tab2 мы вычисляем значение средних продаж 
 * для последюущего их сравнения.
 */
select
	seller,
	round(average_income) as average_income -- округляем значение до целого числа
from tab2
group by 1,2
having round(average_income) < AVG(average_income)
order by average_income
