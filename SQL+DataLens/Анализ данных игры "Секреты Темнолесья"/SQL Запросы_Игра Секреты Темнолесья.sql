/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Лапушкина Ирина Алексеевна
 * Дата: 09.07.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT sum(payer) AS paying_users, 
	count(id) AS total_users, 
	round(avg(payer),4) AS paying_users_share
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT rc.race, 
	sum(us.payer) AS paying_users, 
	count(us.id) AS total_users, 
	round(avg(us.payer),4) AS paying_users_share
FROM fantasy.users AS us
	LEFT JOIN fantasy.race AS rc using(race_id)
GROUP BY race
ORDER BY paying_users_share DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT count(amount) as total_purchases, 
	round(sum(amount::NUMERIC),2) AS total_amount,
	min(amount)::NUMERIC(8,2) AS min_amount, 
    min(amount) FILTER (WHERE amount<>0) AS min_amount_exc_zero,
	max(amount)::NUMERIC(8,2) AS max_amount, 
	avg(amount)::NUMERIC(8,2) AS avg_amount,
	PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY amount)::NUMERIC(8,2) AS med_amount,
	stddev(amount)::NUMERIC(8,2) AS stand_dev_of_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
SELECT count(id) FILTER (WHERE amount=0) AS zero_purchases, 
	count(id) FILTER (WHERE amount=0)/count(id)::real AS zero_purchases_share
FROM fantasy.events;
-- Предмет за 0 у.е:
SELECT game_items
FROM fantasy.events RIGHT JOIN fantasy.items using(item_code)
WHERE amount=0
GROUP BY game_items;
-- Кол-во покупок у игроков за 0 у.е:
SELECT game_items, id, count(id)
FROM fantasy.events RIGHT JOIN fantasy.items using(item_code)
WHERE amount=0
GROUP BY game_items, id;
-- 2.3: Популярные эпические предметы:
SELECT itm.game_items, 
	count(evnt.id) AS item_purchases, 
	count(evnt.id)/(SELECT count(id) FROM fantasy.events WHERE amount<>0)::real AS item_purchases_share,
	count(DISTINCT evnt.id)/(SELECT count(DISTINCT id) FROM fantasy.events WHERE amount<>0)::REAL AS buyers_share
FROM fantasy.items AS itm LEFT JOIN fantasy.events AS evnt using(item_code) 
WHERE amount<>0
GROUP BY itm.game_items
ORDER BY item_purchases desc;
-- Предметы без покупок:
SELECT DISTINCT itm.game_items
FROM fantasy.items AS itm LEFT JOIN fantasy.events AS evnt using(item_code) 
WHERE transaction_id IS null
GROUP BY itm.game_items;
-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH users_count AS
(SELECT rc.race, count(us.id) AS total_users
FROM fantasy.users AS us RIGHT JOIN fantasy.race AS rc using(race_id)
GROUP BY rc.race),
purchases_metrics AS
(SELECT rc.race, 
count(DISTINCT evnt.id) AS buying_users, 
count(DISTINCT evnt.id) FILTER(WHERE payer=1) AS paying_users,
count(transaction_id) AS purchases_number, 
sum(amount) AS total_amount
FROM fantasy.events AS evnt 
RIGHT JOIN fantasy.users AS us using(id) 
RIGHT JOIN fantasy.race AS rc using(race_id)
WHERE amount<>0
GROUP BY rc.race)
SELECT race, 
total_users, 
buying_users, 
round(buying_users/total_users::NUMERIC,5) AS buying_users_share,
round(paying_users/buying_users::NUMERIC,5) AS paying_users_share, 
round(purchases_number/buying_users::NUMERIC,5) AS avg_purchases_number_per_user,
total_amount/purchases_number AS avg_purchase_amount,
total_amount/buying_users AS avg_tot_am_per_user
FROM users_count 
LEFT JOIN purchases_metrics USING(race)
ORDER BY avg_tot_am_per_user DESC;







