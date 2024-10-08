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
    --  объединение имени и фамилии продавца
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
GROUP BY seller -- группировка по продавцу
ORDER BY income DESC -- сортировка по выручке в обратном порядке
LIMIT 10; -- ограничение на 10 записей
/* В итоговом запросе мы получили таблицу с 10-ю продавцами
   с самыми большими суммами продаж. */

/* Запрос по поиску худших продавцов по средней сумме продаж
* lowest_average_income
*/
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    -- соединение имени и фамилии продавца
    FLOOR(
        AVG(s.quantity * p.price)
    ) AS average_income -- вычисляем среднюю сумму продажи по продавцу
FROM sales AS s
LEFT JOIN employees AS e
    ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY seller -- группировка по полю продавец
HAVING (
    SELECT AVG(s.quantity * p.price)
    FROM sales AS s
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
) > AVG(s.quantity * p.price)
ORDER BY average_income;

/* Запрос по поиску продаж продавцов в разрезе дней недели.
 * day_of_week_income
 */
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    -- объеденяем имя и фамилию продавца
    TO_CHAR(s.sale_date, 'Day') AS day_of_week,
    -- выделяем название дня недели
    FLOOR(SUM(p.price * s.quantity)) AS income
    -- вычисление и округление выручки
FROM sales AS s
LEFT JOIN employees AS e
    ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY seller, day_of_week, (EXTRACT(ISODOW FROM s.sale_date) - 1)
-- группировка по продавцу, дню недели, номеру недели
ORDER BY (EXTRACT(ISODOW FROM s.sale_date) - 1);
-- сортировка по номеру дня недели, где Monday = 0

/* Запрос по вычислению количества покупателей в разрезе
 * возрастных групп.
 * age_groups
*/
SELECT
    CASE -- Присвоение категорий каждому диапазону возрастов
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(age) AS age_count
FROM customers
GROUP BY age_category -- группировка по категории возрастов
ORDER BY age_category; -- сортировка по категории возрастов

/* Запрос для вычисления количества уникальных покупателей
 * и выручки в разрезе каждого месяца.
 * customers_by_month
 */
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    -- приведение даты к формату год-месяц
    COUNT(DISTINCT s.customer_id) AS total_customers,
    -- счет уникальных покупателей
    FLOOR(
        SUM(s.quantity * p.price)
    ) AS income -- округление и вычисление выручки
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
    -- объединение имени и фамилии покупателя/продавца
FROM sales AS s
LEFT JOIN customers AS c
    ON s.customer_id = c.customer_id
LEFT JOIN employees AS e
    ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p
    ON s.product_id = p.product_id
WHERE p.price = 0 -- условие выбора записей с ценой = 0
ORDER BY s.customer_id, s.sale_date -- сортировка по id покупателя и дате
/* Итоговая таблица предоставляет даты первых покупок клиентами,
 * соответствующих условиям акции
*/
