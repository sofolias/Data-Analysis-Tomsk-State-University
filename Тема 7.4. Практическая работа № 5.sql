/*	Практическая работа № 5
	Выполнил: Золина Полина Владимировна
*/
/*	Для анализа дана БД Корпорация. В составе 9 таблиц:

01. Таблица "EMPLOYEE" (сотрудники фирмы)
1	employee_id	Код сотрудника
2	last_name	Фамилия
3	first_name	Имя
4	middle_initial	Средний инициал
5	manager_id	Код начальника
6	job_id	Код должности
7	hire_date	Дата поступления в фирму
8	salary	Зарплата
9	commission	Комиссионные
10	department_id	Код отдела

02. Таблица "DEPARTMENT" (отделы фирмы)
1	department_id	Код отдела
2	name	Название отдела
3	location_id	Код места размещения

03. Таблица "LOCATION" (места размещения отделов)
1	location_id	Код места размещения
2	regional_group	Город

04. Таблица "JOB" (должности в фирме)
1	job_id	Код должности
2	functn	Название должности

05. Таблица "CUSTOMER" (фирмы-покупатели)
1	customer_id	Код покупателя
2	name	Название покупателя
3	address	Адрес
4	city	Город
5	state	Штат
6	zip_code	Почтовый код
7	area_code	Код региона
8	phone_number	Телефон
9	salesperson_id	Код сотрудника-продавца, обслуживающего данного покупателя
10	credit_limit	Кредит для покупателя
11	comments	Примечания

06. Таблица "SALES_ORDER" (договоры о продаже)
1	order_id	Код договора
2	order_date	Дата договора
3	customer_id	Код покупателя
4	ship_date	Дата поставки
5	total	Общая сумма договора

07. Таблица "ITEM" (акты продаж)
1	order_id	Код договора, в состав которого входит акт
2	item_id	Код акта
3	product_id	Код продукта
4	actual_price	Цена продажи
5	quantity	Количество
6	total	Общая сумма

08. Таблица "PRODUCT" (товары)
1	product_id	Код продукта
2	description	Название продукта

09. Таблица "PRICE" (цены)
1	product_id	Код продукта
2	list_price	Объявленная цена
3	min_price	Минимально возможная цена
4	start_date	Дата установления цены
5	end_date	Дата отмены цены
*/

-- 1. Для каждого продавца (job_id=670) вывести разность между его зарплатой и средней зарплатой продавцов в отделе № 23.
-- Всего продавцов 11 человек, из них 3 работают в отделе № 23.
-- Cредняя зарплата продавцов в отделе № 23 с округлением до одной десятой:
-- select round(avg(salary),1) from employee where (department_id = '23') and (job_id = '670');

SELECT first_name AS 'Имя', last_name AS 'Фамилия', job_id AS 'ID должности', salary AS 'Заработная плата', (salary - average) AS 'Разность' /*здесь мы вычитаем из зарплаты среднюю зарплату*/
      FROM employee,
	(SELECT AVG(salary) AS average
         FROM employee
         WHERE (job_id=670) and (department_id=23)) temporary /*temporary - это алиас, то есть псевдоним нашей таблицы*/
       WHERE job_id=670
       order by 'Разность';

-- 2. Выбрать среднюю сумму продаж, которая приходится на одного сотрудника в городе NEW YORK.
SELECT avg(total) AS 'Средняя сумма продаж' 
FROM employee e join DEPARTMENT d 
on d.department_id = e.department_id 
join LOCATION l on l.location_id = d.location_id 
join CUSTOMER c on c.salesperson_id = e.employee_id 
join SALES_ORDER so on so.customer_id = c.customer_id
where l.regional_group = 'NEW YORK';

-- 3. Определить максимальное количество проданных экземпляров товара в период с 01.03.2019 по 31.05.2019 года.
select p.product_id AS 'ID товара', p.description AS 'Описание товара', sum(i.quantity)  AS 'Количество'
from PRODUCT p 
join ITEM i on i.product_id = p.product_id 
join SALES_ORDER so on so.order_id = i.order_id 
where year(so.order_date) = 2019 
and month(so.order_date) between 3 and 5 
group by p.product_id
order by sum(i.quantity) desc;

-- 4. Выбрать товары, которые были проданы в максимальном количестве в каждом городе (признак quantity).
-- ДЛЯ ОДНОГО ГОРОДА ОДИН МАКСИМАЛЬНО ПОПУЛЯРНЫЙ ТОВАР
-- MAX ST
SELECT x.loc AS 'Город', product.description AS 'Описание товара', x.st AS 'Количество'
        FROM product, 
          (SELECT SUM(item.quantity) AS st, city AS loc, 
                  product_id AS prod
             FROM department, employee, customer, sales_order, item
             WHERE department.department_id=employee.department_id
             AND employee_id=salesperson_id
             AND customer.customer_id= sales_order.customer_id
             AND sales_order.order_id=item.order_id
             GROUP BY loc, prod ) x,
         (SELECT MAX(st) AS mst, prod, loc
            FROM
               (SELECT SUM(item.quantity) AS st, city AS loc, 
                     product_id AS prod
                  FROM department, employee, customer, sales_order, item
                  WHERE department.department_id= employee.department_id
                  AND employee_id=salesperson_id
                  AND customer.customer_id= sales_order.customer_id
                  AND sales_order.order_id=item.order_id
                  GROUP BY loc, prod) t1 
            GROUP BY prod, loc ) y
      WHERE x.loc = y.loc
        and x.st = y.mst
        and x.prod = product.product_id
  order by 1, 2;
  
--  5. Выбрать данные для построения графика зависимости суммы продажи от процента представленной покупателю скидки.
select i.product_id AS 'ID Продукта', i.total AS 'Сумма продажи', i.actual_price AS 'Цена продажи', p.list_price AS 'Объявленная цена', round(100-((actual_price*100)/list_price),2) AS 'Скидка, %'
from item i
join price p on p.product_id = i.product_id
join sales_order so
on i.order_id = so.order_id
where so.order_date between p.start_date and p.end_date;
