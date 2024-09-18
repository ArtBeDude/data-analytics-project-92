/* Запрос по поиску количества клиентов
* customer_count
*/
SELECT COUNT(customer_id) AS customers_count
FROM customers;

/* Запрос по поиску лучших 10 продавцов по выручке
* top_10_total_income
*/
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(
        SUM(p.price * s.quantity)
    ) AS income,
    -- вычисление суммы выручки каждого продавца
    COUNT(
        CONCAT(e.first_name, ' ', e.last_name)
    ) AS operations
    -- вычисление кол-ва продаж продавца
FROM sales AS s
LEFT JOIN employees AS e
    ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;
/* В итоговом запросе мы получили таблицу с 10-ю продавцами
   с самыми большими суммами продаж. */

/* Запрос по поиску худших продавцов по средней сумме продаж
* lowest_average_income
*/
WITH tab1 AS (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        -- соединение имени и фамилии продавца
        FLOOR(
            AVG(s.quantity * p.price)
        ) AS average_income -- Вычисляем среднюю сумму продажи по продавцу
    FROM sales AS s
    LEFT JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY seller
)

SELECT
    seller,
    average_income
FROM tab1
GROUP BY seller, average_income
HAVING average_income < (SELECT AVG(average_income) FROM tab1)
-- условие сравнение среднего чека продавца с средним общим чеком 
ORDER BY average_income;

/* Запрос по поиску продаж продавцов в разрезе дней недели.
 * day_of_week_income
 */
WITH tab1 AS (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        -- объеденяем имя и фамилию продавца
        (EXTRACT(ISODOW FROM s.sale_date) - 1) AS num_of_day,
        -- приводим нумерацию к Mon = 0
        TO_CHAR(s.sale_date, 'Day') AS day_of_week,
        -- выделяем название дня недели
        FLOOR(SUM(p.price * s.quantity)) AS income
    FROM sales AS s
    LEFT JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY seller, num_of_day, day_of_week
)

SELECT
    seller,
    day_of_week,
    income
FROM tab1
ORDER BY num_of_day, seller;

/* Запрос по вычислению количества покупателей в разрезе
 * возрастных групп.
 * age_groups
*/
SELECT
    COUNT(age) AS age_count,
    CASE -- Присвоение категорий каждому диапазону возрастов
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category
FROM customers
GROUP BY age_category -- группировка по категории возрастов
ORDER BY age_category;

/* Запрос для вычисления количества уникальных покупателей
 * и выручки в разрезе каждого месяца.
 * customers_by_month
 */
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    -- Приведение даты к формату год-месяц
    COUNT(DISTINCT s.customer_id) AS total_customers,
    -- счет уникальных покупателей
    FLOOR(
        SUM(s.quantity * p.price)
    ) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month; -- группировка по месяцу

/* В этом запросе мы будем искать даты первых акционных покупок
 * клиентами.
 * special_offer
*/
SELECT DISTINCT ON (s.customer_id)
-- выбор по первому уникальному id покупателя
    s.sale_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM sales AS s
LEFT JOIN customers AS c
    ON s.customer_id = c.customer_id
LEFT JOIN employees AS e
    ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p
    ON s.product_id = p.product_id
WHERE p.price = 0
ORDER BY s.customer_id, s.sale_date -- сортировка по id покупателя и дате
/* Итоговая таблица предоставляет даты первых покупок клиентами,
 * соответствующих условиям акции
*/
