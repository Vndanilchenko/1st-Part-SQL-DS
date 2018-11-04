------------------------------------- ШАРДИРОВАНИЕ --------------------------------------------

SELECT ('ФИО: Данильченко');

-- создадим партиционированную таблицу
create table links_parted (
	movieid bigint, 
	imdbid character varying(20), 
	tmdbid character varying(20)
);

-- 1я шард-таблица с ограничением - нечет, 2я - четные id-фильмов
create table links_parted_1( check (movieid%2!=0)) inherits (links_parted);
create table links_parted_2( check (movieid%2=0)) inherits (links_parted);

-- создадим правила-триггеры на 2 таблицы
create rule links_insert_1 as on insert to links_parted where (movieid%2!=0) do instead insert into links_parted_1 values (New.*);
create rule links_insert_2 as on insert to links_parted where (movieid%2=0) do instead insert into links_parted_2 values (New.*);


-- проверим работу
insert into links_parted ( select * from links where movieid in (1,2));

-- результат в партиционированной таблице:
select movieid, count(imdbid) from links_parted group by movieid;
/*
 movieid | count 
---------+-------
       2 |     1
       1 |     1
(2 rows)
*/

--1я партиция
select movieid, count(imdbid) from links_parted_1 group by movieid;
/*
 movieid | count 
---------+-------
       1 |     1
(1 row)
*/
--2я партиция
select movieid, count(imdbid) from links_parted_2 group by movieid;
/*
 movieid | count 
---------+-------
       2 |     1
(1 row)
*/

--ПРОВЕРИМ В ОБРАТНУЮ 

--ПОПРОБУЕМ ВСТАВИТЬ ВО 2ю ПАРТИЦИЮ НЕЧЕТНЫЙ id (должен работать только для 1й) 
insert into links_parted_2 ( select * from links where movieid=3);
/*
ERROR:  new row for relation "links_parted_2" violates check constraint "links_parted_2_movieid_check"
DETAIL:  Failing row contains (3, 0113228, 15602).
*/

--ПОПРОБУЕМ ВСТАВИТЬ В 1ю ПАРТИЦИЮ ЧЕТНЫЙ id (должен работать только для 2й) 
insert into links_parted_1 ( select * from links where movieid=2);
/*
ERROR:  new row for relation "links_parted_1" violates check constraint "links_parted_1_movieid_check"
DETAIL:  Failing row contains (2, 0113497, 8844).
*/

-- ОШИБКИ - ПРАВИЛА РАБОТАЮ КОРРЕКТНО
-- проверим с правильными id
insert into links_parted_1 ( select * from links where movieid=5);
-- ошибок нет, нечетный элемент добавлен
select movieid, count(imdbid) from links_parted_1 group by movieid;
/*
 movieid | count 
---------+-------
       5 |     1
       1 |     1
(2 rows)
*/
-- проверим исходную таблицу - вставлены только 3 id: 1 и 2 при тестировании иходной таблицы, 5 при записи на партицию
select movieid, count(imdbid) from links_parted group by movieid;
/*
 movieid | count 
---------+-------
       5 |     1
       2 |     1
       1 |     1
(3 rows)
*/


