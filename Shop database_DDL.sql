/* ОПИСАНИЕ КУРСОВОГО ПРОЕКТА.
База данных интернет-магазина одежды для взрослых
*/

-- СКРИПТЫ СОЗДАНИЯ СТРУКТУРЫ БАЗЫ ДАННЫХ

DROP DATABASE IF EXISTS `shop`;
CREATE DATABASE `shop`;
USE `shop`;


DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	firstname VARCHAR(100),
	lastname VARCHAR(100),
	email VARCHAR(100) UNIQUE,
	password_hash VARCHAR(100),
	phone BIGINT UNSIGNED NOT NULL,
	birthday_date DATE,
	created_at DATETIME DEFAULT NOW(),
	is_deleted BIT DEFAULT b'0'
);

DROP TABLE IF EXISTS bonus_card;
CREATE TABLE bonus_card(
	user_id SERIAL PRIMARY KEY,
	created_at DATETIME DEFAULT NOW(),
	discont BIGINT UNSIGNED, 
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS delivery_type;
CREATE TABLE delivery_type(
	id SERIAL PRIMARY KEY,
	name ENUM('курьер по Москве', 'курьер по Московской области','самовывоз'),
	price BIGINT UNSIGNED NOT NULL
);

DROP TABLE IF EXISTS category;  -- категория товара: "верхняя одежда", "юбки" и т.д.
CREATE TABLE category(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	INDEX category_name_idx(name)
);	

DROP TABLE IF EXISTS article_type;  -- категория товара следующего уровня: "куртки", "плащи", "юбки миди" и т.д.
CREATE TABLE article_type(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),	
	category_id BIGINT UNSIGNED NOT NULL,
	FOREIGN KEY (category_id) REFERENCES category(id) ON UPDATE CASCADE ON DELETE CASCADE,
	INDEX article_type_name_idx(name)
);	

DROP TABLE IF EXISTS brends;
CREATE TABLE brends(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	description VARCHAR(100),
	manager_name VARCHAR(100),
	manager_phone BIGINT UNSIGNED NOT NULL
);

DROP TABLE IF EXISTS articles;
CREATE TABLE articles(
	id SERIAL PRIMARY KEY,
	brends_id BIGINT UNSIGNED NOT NULL,
	name VARCHAR(100),
	gender ENUM('male', 'female'), 
	description VARCHAR(100),
	colour VARCHAR(100),
	size_ ENUM('40', '42', '44', '46', '48', '50', '52', '54', '56'), 
	article_type_id BIGINT UNSIGNED NOT NULL,
	price BIGINT UNSIGNED NOT NULL,
	quantity BIGINT,
	FOREIGN KEY (article_type_id) REFERENCES article_type(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (brends_id) REFERENCES brends(id) ON UPDATE CASCADE ON DELETE CASCADE,
	INDEX articles_name_idx(name)
);

DROP TABLE IF EXISTS orders;
CREATE TABLE orders(
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	article_id BIGINT UNSIGNED NOT NULL, 
	quantity_article INT UNSIGNED NOT NULL,
	/*article_id_2 BIGINT UNSIGNED NOT NULL, 
	quantity_article_2 INT UNSIGNED NOT NULL,
	article_id_3 BIGINT UNSIGNED NOT NULL, 
	quantity_article_3 BIGINT UNSIGNED NOT NULL, */
	-- order_amount BIGINT, -- тут должно быть расчетное поле - стоимость заказа с учетом дисконта покупателя
	delivery_type_id BIGINT UNSIGNED NOT NULL,
	status_payment bit default b'0',
	status_order ENUM('active', 'completed','cancelled'),
	FOREIGN KEY (delivery_type_id) REFERENCES delivery_type(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (article_id) REFERENCES articles(id) ON UPDATE CASCADE ON DELETE CASCADE,
	/*FOREIGN KEY (article_id_2) REFERENCES articles(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (article_id_3) REFERENCES articles(id) ON UPDATE CASCADE ON DELETE CASCADE,*/
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS review;
CREATE TABLE review(
 	user_id BIGINT UNSIGNED NOT NULL, 
 	article_id BIGINT UNSIGNED NOT NULL,
 	order_id BIGINT UNSIGNED NOT NULL,
 	photo BIGINT UNSIGNED,
	body TEXT,
	rating ENUM('1', '2','3','4','5'),
	updated_at DATETIME on update now(),
	PRIMARY KEY (user_id, article_id),
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (article_id) REFERENCES articles(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE CASCADE
);

ALTER TABLE users ADD gender ENUM('male', 'female');