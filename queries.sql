/* Query to determine the number of clients
* customer_count
*/
SELECT COUNT(customer_id) AS customers_count
FROM customers;
/* Вычисление количества клиентов из таблицы "сustomers"*/



/* Request to find the top 10 sellers WITH the highest amounts sales
* top_10_total_income
* In the subquery "tab1" we join the tables according to their id references.
* SELECT the required columns, merge the columns "e.first_name"
* AND "e.last_name" FROM "employees" table
*/
WITH tab1 AS (
    SELECT
        p.product_id,
        s.quantity,
        p.price,
        CONCAT(e.first_name, ' ', e.last_name) AS seller
    FROM sales AS s
    LEFT JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
)

SELECT DISTINCT
    seller, -- Сhoose only unique sellers
    COUNT(*)
        OVER (partition by seller)
    AS operations, -- Вычисление количества операций одного продавца
    FLOOR(
        SUM(quantity * price)
            OVER (partition by seller)
    ) AS income -- Вычисление суммы продаж продавца и округление до целого
FROM tab1
ORDER BY income desc
LIMIT 10;
/* В итоговом запросе мы получили таблицу с 10-ю продавцами
   с самыми большими суммами продаж. */


/* Запрос по поиску худших продавцов по средней сумме продаж
* lowest_average_income
*/
WITH tab1 AS (
    SELECT
        p.product_id,
        s.quantity,
        p.price,
        CONCAT(e.first_name, ' ', e.last_name) AS seller
    FROM sales AS s
    LEFT JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
),

/* В подзапросе "tab1" мы соединяем таблицы согласно референсам их id.
 * Выбираем необходимые столбцы, объеденяем столбцы "e.first_name"
 * и "e.last_name" из таблицы "employees"
 */
tab2 AS (
    SELECT DISTINCT
        seller, -- оставляем только уникальные имена продавцов
        FLOOR(
            AVG(quantity * price)
                OVER (partition by seller)
        ) AS average_income, -- Вычисляем среднюю сумму продажи по продавцу
        AVG(quantity * price)
            OVER ()
        AS avg_total -- Вычисляем среднюю сумму по всем продажам
    FROM tab1
)

SELECT
    seller,
    average_income AS average_income
FROM tab2
GROUP BY 1, 2
HAVING average_income < AVG(avg_total)
ORDER BY average_income

/* Запрос по поиску продаж продавцов в разрезе дней недели.
 * day_of_week_income
 */
WITH tab1 AS (
    SELECT
        p.product_id,
        s.quantity,
        p.price,
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        -- приводим нумерацию к Mon = 0
        (EXTRACT(isodow FROM s.sale_date) - 1) AS num_of_day,
        -- выделяем название дня недели
        TO_CHAR(s.sale_date, 'Day') AS day_of_week
    FROM sales AS s
    LEFT JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
),

/* В подзапросе tab2 мы выводим уникальных продавцов и
 * считаем сумму продаж каждого продавца в партиции продавца и дня недели
 */
tab2 AS (
    SELECT DISTINCT
        seller,
        day_of_week,
        num_of_day,
        SUM(price * quantity)
            OVER (partition by seller, day_of_week)
        AS income
    FROM tab1
    ORDER BY num_of_day, seller
)

SELECT
    seller,
    day_of_week,
    FLOOR(income) AS income
FROM tab2;
/* Итоговая витрина продаж в разрезе продавцов и дней
*/



/* Запрос по вычислению количества покупателей в разрезе
 * возрастных групп.
 * age_groups
*/
WITH tab1 AS (
    SELECT
        *,
        CASE -- Присвоение категорий каждому диапазону возрастов
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END AS age_category
    FROM customers
)

SELECT DISTINCT
    age_category,
    -- подсчёт количества покупателей в категории
    COUNT(age) OVER (partition by age_category) AS age_count
FROM tab1
ORDER BY age_category;
--------------------------------------------------------------
/* В этом подзапросе мы вычисляем количество уникальных покупателей
 * и выручки в разрезе каждого месяца.
 * customers_by_month
 */
WITH tab1 AS ( -- В подзапросе tab1 происходит приведение данных
   SELECT -- к необходимым типам.
      TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
      CONCAT(c.first_name, ' ', c.last_name) AS customer_name
   FROM sales AS s
   LEFT JOIN customers AS c
   ON s.customer_id = c.customer_id
),
tab2 AS (     -- В подзапросе tab2 мы находим уникальных покупателей в каждом месяце.
    SELECT DISTINCT 
        customer_name,
        selling_month
    FROM tab1
),
tab3 AS (     -- В подзапросе tab3 мы находим количество уникальных покупателей
    SELECT DISTINCT -- в разрезе каждого месяца.
        DISTINCT selling_month,
        COUNT(customer_name)
           OVER (partition by selling_month)
   FROM tab2
),
tab4 AS (     -- tab4 представляет собой CTE с данными для подсчета суммарной выручки
    SELECT        -- в итоговом запросе.
        TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
        p.product_id,
        s.quantity,
        p.price
    FROM sales AS s
    LEFT JOIN products AS p
    ON s.product_id = p.product_id
)
SELECT DISTINCT 
    tab4.selling_month,
    tab3.COUNT AS total_customers,
    FLOOR(SUM(tab4.price * tab4.quantity) 
        OVER (partition by tab4.selling_month)) AS income
FROM tab4
INNER JOIN tab3
ON tab4.selling_month = tab3.selling_month;
/* В итоговом запросе мы соеденили CTE tab4 и tab3 по месяцам,
 * посчитали и округлили суммарную выручку по месяцам и указали количество уникальных клиентов
 * в каждом месяце
 */



/* В этом запросе мы будем искать даты первых акционных покупок
 * клиентами.
 * special_offer
*/

WITH tab1 AS (
   SELECT         
      s.customer_id,
      CONCAT(c.first_name, ' ', c.last_name) AS customer, - объеденяем имя и фамилию
      sale_date,
      CONCAT(e.first_name, ' ', e.last_name) AS seller,
      p.price,
      ROW_NUMBER () -- присваиваем номера в партиции клиент, продавец с сортировкой по дате ASC
         OVER (partition by CONCAT(c.first_name, ' ', c.last_name),  
            CONCAT(e.first_name, ' ', e.last_name) 
            ORDER BY sale_date) AS flag_1,
      ROW_NUMBER () -- присваиваем номер каждой записи с клиентом для последующего отбора первого значения
         OVER (partition by CONCAT(c.first_name, ' ', c.last_name)) AS flag_2 
   FROM sales AS s
   LEFT JOIN customers AS c
   ON s.customer_id = c.customer_id
   LEFT JOIN employees AS e
   ON s.sales_person_id = e.employee_id
   LEFT JOIN products AS p
   ON s.product_id = p.product_id
   WHERE price = 0 - условие выбора записей соответствующее акции
)
SELECT
   customer,
   sale_date,
   seller
FROM tab1 
WHERE flag_1 = 1 AND flag_2 = 1 -- выбор flag_1 = первая клиент-дата, flag_2 = одна запись - один клиент
ORDER BY customer_id; -- сортировка записей по id клиента
/* Итоговая таблица предоставляет даты первых покупок клиентами соответствующих условиям акции
*/
