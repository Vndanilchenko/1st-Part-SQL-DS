---------------------------- практическая работа ---------------------------------------
----------------------------- Данильченко В.Н. -----------------------------------------
----------------------------анализ отзывов Yelp ----------------------------------------

select ('Данильченко В');

------------------------- подготовка ------------------------------------------------

-- копируем файлы в контейнер
select('копируем файлы в контейнер: sudo docker cp /tmp/yelp_review.csv e12f22e691e2:/data/yelp_review.csv')

-- создаем таблицу с описанием заведений. связь со всеми таблицами по business_id
create table business (business_id varchar,name varchar, neighborhood varchar,address varchar, city varchar,state varchar,postal_code varchar, latitude decimal,longitude decimal, stars decimal,review_count integer,is_open integer,categories text);
/*
CREATE TABLE
*/
--заполняем таблицу
\copy business from '/data/yelp_business.csv' DELIMITER ',' CSV HEADER;
/*
COPY 174567
*/
-- создадим таблицу особенностей бизнеса. связь с business по business_id
create table business_attributes (business_id varchar, AcceptsInsurance varchar, ByAppointmentOnly varchar, BusinessAcceptsCreditCards varchar, BusinessParking_garage varchar, BusinessParking_street varchar, BusinessParking_validated varchar, BusinessParking_lot varchar, BusinessParking_valet varchar, HairSpecializesIn_coloring varchar, HairSpecializesIn_africanamerican varchar, HairSpecializesIn_curly varchar, HairSpecializesIn_perms varchar, HairSpecializesIn_kids varchar, HairSpecializesIn_extensions varchar, HairSpecializesIn_asian varchar, HairSpecializesIn_straightperms varchar, RestaurantsPriceRange2 varchar, GoodForKids varchar, WheelchairAccessible varchar, BikeParking varchar, Alcohol varchar, HasTV varchar, NoiseLevel varchar, RestaurantsAttire varchar, Music_dj varchar, Music_background_music varchar, Music_no_music varchar, Music_karaoke varchar, Music_live varchar, Music_video varchar, Music_jukebox varchar, Ambience_romantic varchar, Ambience_intimate varchar, Ambience_classy varchar, Ambience_hipster varchar, Ambience_divey varchar, Ambience_touristy varchar, Ambience_trendy varchar, Ambience_upscale varchar, Ambience_casual varchar, RestaurantsGoodForGroups varchar, Caters varchar, WiFi varchar, RestaurantsReservations varchar, RestaurantsTakeOut varchar, HappyHour varchar, GoodForDancing varchar, RestaurantsTableService varchar, OutdoorSeating varchar, RestaurantsDelivery varchar, BestNights_monday varchar, BestNights_tuesday varchar, BestNights_friday varchar, BestNights_wednesday varchar, BestNights_thursday varchar, BestNights_sunday varchar, BestNights_saturday varchar, GoodForMeal_dessert varchar, GoodForMeal_latenight varchar, GoodForMeal_lunch varchar, GoodForMeal_dinner varchar, GoodForMeal_breakfast varchar, GoodForMeal_brunch varchar, CoatCheck varchar, Smoking varchar, DriveThru varchar, DogsAllowed varchar, BusinessAcceptsBitcoin varchar, Open24Hours varchar, BYOBCorkage varchar, BYOB varchar, Corkage varchar, DietaryRestrictions_dairy_free varchar, DietaryRestrictions_gluten_free varchar, DietaryRestrictions_vegan varchar, DietaryRestrictions_kosher varchar, DietaryRestrictions_halal varchar, DietaryRestrictions_soy_free varchar, DietaryRestrictions_vegetarian varchar, AgesAllowed varchar, RestaurantsCounterService varchar);
-- заполним ее из .csv
\copy business_attributes from '/data/yelp_business_attributes.csv' DELIMITER ',' CSV HEADER;
/*
COPY 152041
*/
-- создадим и заполним таблицу с отметками пользователей в этом заведении. связь с business по business_id
create table checkin (business_id varchar,weekday varchar,hour time, checkins integer);
/*
CREATE TABLE
*/
--заполним ее из csv
\copy checkin from '/data/yelp_checkin.csv' DELIMITER ',' CSV HEADER;
/*
COPY 3911218
*/
-- создадим таблицу с отзывами клиентов. связь business_id и user_id для связи с пользователями в последующих таблицах
-- посмотрим заголовки, тк файл большой
head -n 2 /data/yelp_review.csv
create table review (review_id varchar, user_id varchar, business_id varchar, stars integer, "date" date, "text" text, useful integer, funny integer, cool integer);
/*
CREATE TABLE
*/
--заполним ее из csv
\copy checkin from '/data/yelp_checkin.csv' DELIMITER ',' CSV HEADER;

-- создадим таблицу пользователей
create table yelp_users (user_id varchar, "name" varchar, "review_count" integer, "yelping_since" date, "friends" text, "useful" integer, "funny"integer, "cool" integer, "fans" integer, "elite" varchar, "average_stars" decimal, "compliment_hot" integer,"compliment_more" integer,"compliment_profile" integer,"compliment_cute" integer,"compliment_list" integer, "compliment_note"integer, "compliment_plain" integer, "compliment_cool" integer,"compliment_funny" integer,"compliment_writer" integer,"compliment_photos" integer);
-- заполним ее данными
\copy yelp_users from '/data/yelp_user.csv' DELIMITER ',' CSV HEADER;
/*
COPY 1326100
*/

------------------------- запросы ------------------------------------------------
-- посмотрим на данные, сгруппировав по штатам:
---- state_from_all - доля записей в штате из всех записей
---- recs_state - количество записей(заведений) в штате
---- recs_open - количество открытых на данный момент заведений 
---- part_open_in_state - посчитаем долю открытых на данный момент заведений из всех с отзывами
select bs1.state, 
	round((count(bs1.*)/(select count(*) from business)::decimal)*100,2) state_from_all, 
	count(bs1.*) recs_state, 
	count(bs2.*) recs_open, 
	round((count(bs2.*)/count(bs1.*)::decimal)*100,2) part_open_in_state 
from business bs1 left join (select * from business where is_open=1) bs2 on bs1.business_id=bs2.business_id 
group by bs1.state 
order by count(bs1.*) desc; 

/*
 state | state_from_all | recs_state | recs_open | part_open_in_state 
-------+----------------+------------+-----------+--------------------
 AZ    |          29.91 |      52214 |     44045 |              84.35
 NV    |          18.95 |      33086 |     27491 |              83.09
 ON    |          17.30 |      30208 |     24723 |              81.84
 NC    |           7.42 |      12956 |     11099 |              85.67
 OH    |           7.22 |      12609 |     10920 |              86.60
 PA    |           5.79 |      10109 |      8663 |              85.70
 QC    |           4.68 |       8169 |      6925 |              84.77
 WI    |           2.72 |       4754 |      3973 |              83.57
 EDH   |           2.17 |       3795 |      3078 |              81.11
 BW    |           1.79 |       3118 |      2746 |              88.07
 IL    |           1.06 |       1852 |      1531 |              82.67
 SC    |           0.39 |        679 |       572 |              84.24
 MLN   |           0.12 |        208 |       176 |              84.62
 HLD   |           0.10 |        179 |       170 |              94.97
 NYK   |           0.09 |        152 |       145 |              95.39
 CHE   |           0.08 |        143 |       134 |              93.71
 FIF   |           0.05 |         85 |        82 |              96.47
....
*/
------ тк не обладаем данными о численности и территории штатов, делаем выводы только о активности пользователей 
------ можем сказать, основная масса оцененных заведений(66%) из трех штатов - Аризона (AZ, 29.91%), Невада (NV, 18.95%) и провинция Онтарио (ON, 17.3%)
-- проверим какой средний процент открытых заведений для штатов по градации 0-500, 500-1000, 1000-5000, 5000-10000, 10000-50000 и посчитаем долю штатов, находящихся в этих диапазонах
with biz as (
	select bs1.state, 
		round((count(bs1.*)/(select count(*) from business)::decimal)*100,2) state_from_all, 
		count(bs1.*) recs_state, 
		count(bs2.*) recs_open, 
		round((count(bs2.*)/count(bs1.*)::decimal)*100,2) part_open_in_state 
	from business bs1 left join (select * from business where is_open=1) bs2 on bs1.business_id=bs2.business_id 
	group by bs1.state) 
select round((select avg(part_open_in_state) from biz where recs_state<500),2) less_500, 
	round((select avg(part_open_in_state) from biz where recs_state between 500 and 1000),2) between_500_1000, 
	round((select avg(part_open_in_state) from biz where recs_state between 1000 and 5000),2) between_1k_5k, 
	round((select avg(part_open_in_state) from biz where recs_state between 5000 and 10000),2) between_5k_10k, 
	round((select avg(part_open_in_state) from biz where recs_state between 10000 and 50000),2) between_10k_50k, 
	round((select avg(part_open_in_state) from biz),2) avg_all, 
	round((select count(state) from biz where recs_state<500)/(select count(state) from biz)::decimal,2) states_ls_500, 		round((select count(state) from biz where recs_state between 500 and 1000)/(select count(state) from biz),2) states_500_1000, 
	round((select count(state) from biz where recs_state between 1000 and 5000)/(select count(state) from biz)::decimal,2) states_1k_5k, 
	round((select count(state) from biz where recs_state between 5000 and 10000)/(select count(state) from biz)::decimal,2) states_5k_10k, 
	round((select count(state) from biz where recs_state between 10000 and 50000)/(select count(state) from biz)::decimal,2) states_10_50k 
;
/*
 less_500 | between_500_1000 | between_1k_5k | between_5k_10k | between_10k_50k | avg_all | states_ls_500 | states_500_1000 | states_1k_5k | states_5k_10k | states_10_50k 
----------+------------------+---------------+----------------+-----------------+---------+---------------+-----------------+--------------+---------------+---------------
    92.61 |            84.24 |         83.86 |          84.77 |           84.58 |   91.14 |          0.82 |            0.00 |         0.06 |          0.01 |          0.07
*/
------ средний процент открытых заведений равен 91%, но эту среднюю вытягивают вверх штаты с малой долей оценок (таких 82% штатов и провинций с оцененными менее 500 заведений), для остальных доля открытых заведений колеблется от 83 до 85%

-- проверим гипотезу - закрываются заведения с низким рейтингом и небольшой проходимостью
select case when is_open=1 then 'open' when is_open=0 then 'closed' end state, 
	round(avg(stars),2) avg_raiting,
	round(avg(review_count),2) avg_reviews 
from business 
group by is_open;
/*
 state  | avg_raiting | avg_reviews 
--------+-------------+-------------
 closed |        3.51 |       22.17
 open   |        3.65 |       31.65

*/
------ по средним рейтингам видно небольшое отклонение в меньшую сторону для закрытых заведений
---- посмотрим в разбивке по ТОП 3 по количеству штатам
select state, 
	case when is_open=1 then 'open' when is_open=0 then 'closed' end condition, 
	round(avg(stars),2) avg_raiting,
	round(avg(review_count),2) avg_reviews
from business 
where state in (select bs.state 
		from business bs  
		group by bs.state 
		order by count(*) desc 
		limit 3) 
group by state, is_open 
order by state;
/*
 state | condition | avg_raiting | avg_reviews 
-------+-----------+-------------+-------------
 AZ    | open      |        3.76 |       32.64
 AZ    | closed    |        3.55 |       23.25
 NV    | open      |        3.73 |       58.48
 NV    | closed    |        3.61 |       38.74
 ON    | open      |        3.42 |       22.21
 ON    | closed    |        3.36 |       15.53
(6 rows)
*/
------ видим ту же картину в разрезе штатов - закрытые заведения имеют меньший средний рейтинг и меньшее количество отзывов(можно приравнять к проходимости)
------ также видно, что самые "оцененные" заведения в Неваде (59 среди открытых, больше на 79% от ближайшей по значению Аризоны)


-- ПРОВЕРИМ РАЗЛИЧИЯ МЕЖДУ ЗАКРЫТЫМИ И ОТКРЫТЫМИ ЗАВЕДЕНИЯМИ В НАЛИЧИИ ДОПОЛНИТЕЛЬНОГО СЕРВИСА ДЛЯ КЛИЕНТА 

------ проверим долю заведений, которые принимаю кредитные карты к оплате в сравнении открытых заведений с закрытыми
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.BusinessAcceptsCreditCards 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.BusinessAcceptsCreditCards='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.BusinessAcceptsCreditCards='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.BusinessAcceptsCreditCards='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.BusinessAcceptsCreditCards='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.BusinessAcceptsCreditCards='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/*
 is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |       1012 |           1120 |         0.47
       1 |      10119 |          11330 |         0.47
(2 rows)
*/
------ ВЫВОД: доля заведений, принимающих к оплате Крединые карты, не отличается у закрытых и открытых заведений, видимо этот признак не является значимым в описании заведений "меньшего интереса" со стороны клиентов
------ bikeParking - парковка для мотоциклов
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.bikeParking 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.bikeParking='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.bikeParking='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.bikeParking='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.bikeParking='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.bikeParking='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/*
is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |       7614 |           1033 |         0.88
       1 |      26431 |           4204 |         0.86
(2 rows)
*/
------ ВЫВОД: доля парковки для мотоциклов больше среди закрытых

------ wheelChairAccessible - адаптировано для инвалидов
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.wheelChairAccessible 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wheelChairAccessible='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wheelChairAccessible='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wheelChairAccessible='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wheelChairAccessible='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wheelChairAccessible='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/*
 is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |       4178 |            945 |         0.82
       1 |      13660 |           2191 |         0.86
(2 rows)
*/
------ ВЫВОД: места, адаптированные для посещения инвалидами, встречается чаще в открытых 

------ businessParking_valet
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.businessParking_valet 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.businessParking_valet='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.businessParking_valet='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.businessParking_valet='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.businessParking_valet='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.businessParking_valet='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/*
 is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |       3875 |           6404 |         0.38
       1 |      10723 |          18352 |         0.37
(2 rows)
*/

------ WiFi
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.wifi 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wifi='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wifi='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wifi='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wifi='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.wifi='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/* is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |          9 |              8 |         0.53
       1 |         51 |             29 |         0.64
(2 rows)
*/
------ ВЫВОД: wifi встречался реже среди закрытых в данный момент заведений (хотя выборка мала для однозначного вывода)

------ open24hours
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.open24hours 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.open24hours='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.open24hours='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.open24hours='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.open24hours='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.open24hours='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/*
 is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |          4 |             91 |         0.04
       1 |         57 |           1289 |         0.04
(2 rows)
*/
------ ВЫВОД: нет различий, выборка мала

------ dogsallowed
with biz_attr as (select bs.business_id, 
			bs.is_open, 
			ba.dogsallowed 
		from business bs left join business_attributes ba on bs.business_id=ba.business_id) 
select is_open, 
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.dogsallowed='True') allowed_CC,
	(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.dogsallowed='False') not_allowed_CC, 
	round((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.dogsallowed='True')/((select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.dogsallowed='False')+(select count(*) from biz_attr ba1 where ba1.is_open=ba_main.is_open and ba1.dogsallowed='True'))::decimal,2) part_allowed 
from biz_attr ba_main 
group by is_open;
/*
 is_open | allowed_cc | not_allowed_cc | part_allowed 
---------+------------+----------------+--------------
       0 |        113 |            646 |         0.15
       1 |       2233 |           3013 |         0.43
(2 rows)
*/
------ ВЫВОД: среди открытых встречается гораздо чаще

------ ИТОГ: наличие дополнительных удобств, таких как возможность посещения заведения с домашними питомцами, wifi, оборудованные для посещения инвалидами помещения, является необходимым атрибутом существования бизнеса. Возможно ввиду отсутсвия подобного сервиса заведения получали более низкие рейтинги.

-- ОПРЕДЕЛИМ КАТЕГОРИИ БИЗНЕСА (у нас записаны сторокой в поле categories)
---- выглядит примерно так: Dentists;General Dentistry;Health & Medical;Oral Surgeons;Cosmetic Dentists;Orthodontists. Для этого нам нужно создать функцию, которая
---- 1) с помощью регулярных выражений разделяет стоку по словам, используя разделителем любой символ и приведит ее к виду Dentists;General;Dentistry;Health;Medical;Oral;Surgeons;Cosmetic;Dentists;Orthodontists
---- 2) преобразует строку в  массив
/*
{Dentists,General,Dentistry,Health,Medical,Oral,Surgeons,Cosmetic,Dentists,Orthodontists}
(1 row)
*/
---- 3) разделяет по строкам, удаляет дубли, считает повторения
/*
    unnest     | count 
---------------+-------
 Surgeons      |     1
 Cosmetic      |     1
 Dentistry     |     1
 General       |     1
 Health        |     1
 Orthodontists |     1
 Dentists      |     2
 Oral          |     1
 Medical       |     1
(9 rows)
*/
---- 4) выводит строку с максимальным количеством повторений слова в строке - это и будет наша категория
/*
  unnest  | count 
----------+-------
 Dentists |     2
(1 row)
*/

create or replace function category (text) returns varchar language sql as $FUNCTION$ 
	with T as (select string_to_array(regexp_replace($1,'\W+',';','g'),';') arr1)
	select category from(
		select distinct unnest(arr1) category
		,count(*)
		from T 
		group by unnest(arr1) 
		order by count(*) desc 
		limit 1
	) TT;
$FUNCTION$;
/*
 category 
----------
 Dentists
(1 row)
*/
---- посмотрим на категории, численность заведений в которых более 4000
with cats as (select distinct state, 
		category(categories) sphere, 
		count(*) cnt  
	from business 
	group by state, category(categories)) 
select sphere, 
	sum(cnt) 
from cats 
group by sphere 
having sum(cnt)>4000
order by sum(cnt) desc; 
/*
   sphere    |  sum  
-------------+-------
 Restaurants | 11433
 Services    |  8870
 Shopping    |  7321
 Food        |  6958
 Beauty      |  5930
 Home        |  5851
 Hair        |  5706
 Active      |  5563
 Nightlife   |  5464
 Bars        |  4905
 Automotive  |  4282
 Medical     |  4191
(12 rows)
*/
------ видим на 1м месте ретораны, их на 29% больше ближайшего соседа из сферы услуг
---- выведем в каждом из штатов по 1 категории с наибольшим рейтингом при условии, что предприятий в категории будет более 500
with cats as (select distinct state, 
		category(categories) sphere, 
		count(*) cnt, round(avg(stars),2) avg_raiting  
	from business 
	group by state, category(categories)) 
select state, 
	sphere, 
	items, 
	avg_raiting 
from (select row_number() over (partition by state order by state, sphere, avg_raiting desc) rnbr,  
		state, 
		sphere, 
		sum(cnt) items, 
		avg_raiting 
	from cats 
	where cnt>500 
	group by state, sphere, avg_raiting 
	order by state, sphere, avg_raiting desc) T 
where rnbr=1 
order by avg_raiting desc;
/*
 state |   sphere    | items | avg_raiting 
-------+-------------+-------+-------------
 NV    | Active      |  1101 |        4.23
 AZ    | Active      |  1759 |        4.15
 QC    | Food        |   612 |        3.96
 NC    | Food        |   501 |        3.80
 ON    | Active      |   893 |        3.72
 PA    | Restaurants |   836 |        3.49
 OH    | Bars        |   563 |        3.48
(7 rows)
*/
------ видим, что в Неваде (NV) самый большой средний рейтинг во всех штатах, а также категория с этим рейтингом "Active". Что же это за категория?..
select categories from business where category(categories)='Active' limit 10;
/*
                                                     categories                                                     
--------------------------------------------------------------------------------------------------------------------
 Fitness & Instruction;Sports Clubs;Gyms;Trainers;Active Life
 Active Life;Fitness & Instruction;Gyms
 Health & Medical;Active Life;Weight Loss Centers;Fitness & Instruction;Trainers;Nutritionists;Gyms
 Hiking;Active Life
 Active Life;Sports Clubs;Gyms;Fitness & Instruction;Trainers
 Yoga;Active Life;Fitness & Instruction
 Active Life;Boot Camps;Trainers;Fitness & Instruction;Gyms
 Active Life;Parks;Local Flavor
 Active Life;Sporting Goods;Karate;Education;Shopping;Martial Arts;Specialty Schools;Trainers;Fitness & Instruction
 Yoga;Health & Medical;Active Life;Fitness & Instruction;Physical Therapy;Trainers
(10 rows)
*/
------ эту сферу можно описать как "Активный образ жизни", т.е. фитнес, тренировки в парках, тренажерные залы
------ видим, что штаты NV и AZ одни из самых южных штатов Америки, наверно по причине теплого климата такое большое количество заведений для активного отдыха, которые могут функционировать круглый год, а Квебек и Северная Каролина (QC, NC) расположены близко к морю и океану - возможно продуктовые магазины, через которые реализуют продовольственные поставки, в данных местах имеют большую возможность предлагать свежую продукцию, т.е. ввиду расположения качество продуктов лучше и это отмечают посетители. Но это лишь мои поверхностные выводы :)

-- НАЙДЕМ САМОГО ДРУЖЕЛЮБНОГО ПОСЕТИТЕЛЯ (с максимальным количеством друзей)
---- изначально данные представлены в текстовой строке с разделением по запятым, нужно преобразовать в массив и посчитать его длину
select user_id, 
	array_length(string_to_array(friends, ','),1) 
from yelp_users 
group by user_id,friends 
order by array_length(string_to_array(friends, ','),1) desc 
limit 1;
/*
        user_id         | array_length 
------------------------+--------------
 qVc8ODYU5SZjKXVBgXdI7w |        14995
(1 row)

*/
------т.е. пользователь с id выше мега-дружелюбен - 14995 записей о друзьях
---- вытащим первого друга в списке для каждого пользователя и найдем самое популярное имя среди них
------ для этого преобразуем строку со списком id в массив, выберем каждый первый элемент, лефтджойним к таблице юзеров, вытаскиваем имя, сортируем по убыванию количества повторений, исключаем нулы, берем первую запись 
select name 
from 	(select name 
	from (select friends_arr[1] fst_friend_id 
		from (select string_to_array(friends, ',') friends_arr 
			from yelp_users) T
		) first_friend left join yelp_users us on first_friend.fst_friend_id=us.user_id 
		where name is not null
		group by name 
		order by count(*) desc 
		limit 1
	) TT; 
/*
  name   
---------
 Michael
(1 row)
*/

-- что успел. так еще можно много интересного тут сделать - рекомендации друзей пользователям, сравнение рейтинга среди друзей, наихудший рейтинг и тд :)
