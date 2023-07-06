-- СКРИПТЫ ХАРАКТЕРНЫХ ВЫБОРОК

-- 1. Посчитать количество мужчин и женщин с 20%-ной дисконтной картой

SELECT gender, COUNT(*) AS cnt
FROM users
WHERE id IN 
           (SELECT user_id FROM bonus_card WHERE discont = 20)
GROUP BY gender; 


-- 2. Определить средний возраст активных пользователей, совершивших заказы в интернет-магазине

SELECT ROUND (AVG( YEAR(now()) - YEAR (birthday_date))) AS average_users_age
FROM users 
WHERE id IN 
           (SELECT user_id FROM orders WHERE status_order <> 'cancelled');


-- 3. Определить наиболее популярный способ доставки
          
 SELECT 
   dt.name, 
   COUNT(*) AS cnt
 FROM orders o 
   JOIN delivery_type dt ON o.delivery_type_id = dt.id 
 WHERE o.status_order <> 'cancelled'
 GROUP BY o.delivery_type_id 
 ORDER BY cnt DESC
 LIMIT 1;  
         

-- 4. Вывести, какое количество единиц одежды каждого бренда было заказано и на какую общую сумму

SELECT 
  b.name AS brend, 
  SUM(o.quantity_article) AS art_ordered,
  SUM(o.quantity_article * a.price) AS sum_of_orders 
FROM orders o 
  JOIN articles a ON o.article_id = a.id 
  JOIN brends b ON a.brends_id = b.id 
WHERE o.status_order <> 'cancelled'
GROUP BY b.name
ORDER BY art_ordered DESC; 


-- 5. Отобразить топ-3 категорий товаров, позиции из которых наиболее часто заказывали люди младше 35 лет

SELECT 
  c.name,
  COUNT(o.article_id) AS cnt
FROM category c
  JOIN article_type at2 ON c.id = at2.category_id 
  JOIN articles a ON at2.id = a.article_type_id 
  JOIN orders o ON a.id = o.article_id
  JOIN users u ON o.user_id = u.id 
WHERE ((YEAR(now()) - YEAR(u.birthday_date)) < 35)
AND (o.status_order <> 'cancelled')
GROUP BY c.name
ORDER BY cnt DESC
LIMIT 3;


-- 6. Найти пользователя, оставившего наибольшее количество отзывов на заказанные товары

SELECT 
  u.id ,
  u.firstname,
  u.lastname,
  YEAR(now()) - YEAR(u.birthday_date)  AS age,
  COUNT(*) AS cnt_of_reviews
FROM review r
  JOIN users u  ON r.user_id = u.id 
GROUP BY u.id 
ORDER BY cnt_of_reviews DESC
LIMIT 1;


/* ХРАНИМАЯ ПРОЦЕДУРА
Выводить по 5 произвольных наименований товаров из той же категории и того же бренда, 
к которым принадлежал товар из последнего оформленного покупателем заказа */

ALTER TABLE orders ADD created_at DATETIME DEFAULT NOW();
UPDATE orders 
SET created_at = '2023-01-02 22:08:10'
WHERE user_id >50;
UPDATE orders 
SET created_at = '2023-03-04 22:08:10'
WHERE quantity_article < 3;
UPDATE orders 
SET created_at = '2022-09-10 22:08:10'
WHERE article_id  > 150;


DROP PROCEDURE IF EXISTS sp_article_offers;

DELIMITER //
CREATE PROCEDURE sp_article_offers(IN for_user_id BIGINT)
BEGIN
-- единая таблица со всеми необходимыми данными
	WITH full_orders AS ( 
       SELECT 
         o.id  AS order_id,
         o.user_id,
         o.article_id,
         a.brends_id,
         c.id  AS category_id,
         o.created_at 
       FROM orders o 
         JOIN articles a  ON o.article_id = a.id 
         JOIN article_type at2  ON  at2.id = a.article_type_id 
         JOIN category c ON c.id = at2.category_id 
     )
-- артикли той же категории	
    SELECT 
      fo2.article_id
    FROM full_orders fo1
      JOIN full_orders fo2 ON fo1.category_id = fo2.category_id
    WHERE fo1.user_id = for_user_id
      AND fo2.article_id <> fo1.article_id
      AND fo1.created_at IN (
               SELECT MAX(fo1.created_at) 
               FROM full_orders fo1
               WHERE fo1.user_id = for_user_id
               )   
-- артикли того же бренда    
    UNION 
    SELECT 
      fo2.article_id 
    FROM full_orders fo1
      JOIN full_orders fo2 ON fo1.brends_id = fo2.brends_id
    WHERE fo1.user_id = for_user_id
      AND fo2.article_id <> fo1.article_id
      AND fo1.created_at IN (
               SELECT MAX(fo1.created_at) 
               FROM full_orders fo1
               WHERE fo1.user_id = for_user_id
               )  
     
    ORDER BY rand()  
    LIMIT 5;
     
END //
DELIMITER ; 

CALL sp_article_offers(5);



/*ПРЕДСТАВЛЕНИЯ.
 1. Каталог товаров магазина  */

CREATE OR REPLACE VIEW v_katalog 
AS
SELECT
  a.id AS article_id,
  a.name AS article_name,
  a.gender ,
  b.name AS brend,
  c.name AS category ,
  at2.name AS article_type_id ,
  a.quantity AS availability
FROM articles a 
  JOIN  article_type at2  ON  at2.id = a.article_type_id 
  JOIN category c ON c.id = at2.category_id
  JOIN brends b ON b.id = a.brends_id
ORDER BY a.id ; 
 
 SELECT * FROM v_katalog vk;


-- 2. Бренды с наивышим рейтингом товаров 

CREATE OR REPLACE VIEW v_popular_brends 
AS
SELECT
  b.name AS brend,
  ROUND(AVG(r.rating)) AS average_rating,
  SUM(o.quantity_article) AS quantity_of_odered_articles
FROM review r 
  JOIN articles a ON r.article_id = a.id 
  JOIN brends b ON b.id = a.brends_id 
  JOIN orders o ON o.article_id = a.id 
WHERE o.status_order  <> 'cancelled'
GROUP BY brend 
ORDER BY average_rating DESC; 

SELECT * FROM v_popular_brends ;


/*ТРИГГЕРЫ.
 Проверка корректного ввода возраста для нового пользователя  */

DELIMITER //
CREATE TRIGGER check_user_age_before_insert
BEFORE INSERT
ON users FOR EACH ROW
BEGIN 
	IF NEW.birthday_date > NOW()  THEN 
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Введена некорректная дата рождения';
	END IF;
END //
DELIMITER ;



-- Расчет цены со скидкой 20% для утепленных курток

DELIMITER //
CREATE TRIGGER `discont_for_утепленные куртки`
BEFORE INSERT
ON articles FOR EACH ROW
BEGIN
        IF  article_type_id = 21 THEN 
        SET NEW.price = price * 0.8; 
        END IF;
END //
DELIMITER ;














