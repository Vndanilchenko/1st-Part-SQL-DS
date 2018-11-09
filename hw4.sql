-------------------------- Работа с PostgreSQL ------------------------------------

SELECT ('ФИО: Данильченко Вадим');

--выберем ТОП 5 таблиц по размеру
select relname, relpages 
from pg_class 
order by relpages desc 
limit 5; 
/*
  relname  | relpages 
-----------+----------
 ratings   |     5719
 keywords  |      923
 links     |      292
 pg_proc   |       74
 pg_depend |       54
(5 rows)
*/

-- построим простую рекомендательную систему

-- соберем все уникальные фильмы, просмотренные пользователем, в массив и сохраним в public.user_movies_agg

select userid, array_agg(distinct movieid) as user_views 
into public.user_movies_agg  
from ratings 
group by userid;

--создадим функцию, возвращающую пересечение id фильмов у разных пользователей
create or replace function cross_arr (bigint[],bigint[]) returns bigint[] language sql as $FUNCTION$ 
	with tbl1 as (
		select unnest($1) as movieid intersect select unnest($2)
		) 
	select array_agg(movieid) 
	from tbl1; 
$FUNCTION$;

with tbl1 as (select unnest($1) as movieid intersect select unnest($2)) select array_agg(movieid) from tbl1;

-- cформируем все возможные комбинации между пользователями
select distinct t1.userid ur1, array_agg(t1.movieid) ar1, t2.userid ur2, array_agg(t2.movieid) ar2 
from ratings t1 cross join ratings t2 
group by ur1, ur2 
limit 10;

-- создадим короткую версию таблицы ratings, в которую сохраним 10т записей исходной таблицы - ratings_short
select * 
into ratings_short 
from ratings 
limit 10000; 
 
-- пропустим через функцию, отсортируем по убыванию длины массива и сохраним ТОП 10 по размеру пересечений в common_user_views 
with CTE as 
	(select distinct t1.userid ur1, array_agg(t1.movieid) ar1, t2.userid ur2, array_agg(t2.movieid) ar2 
	from ratings_short t1 cross join ratings_short t2 
	group by t1.userid, t2.userid) 
select ur1, ur2, cross_arr(ar1,ar2) arr_res 
into common_user_views 
from CTE 
where ur1!=ur2 and cross_arr(ar1,ar2) is not null 
order by array_length(cross_arr(ar1,ar2),1) desc 
limit 10;

-- создадим функцию, отбрасывающую пересечение и отображающая оставшееся
create or replace function diff_arr (bigint[],bigint[]) returns bigint[] language sql as $FUNCTION$ 
	with tbl2 as (
		select unnest($1) as movieid except select unnest($2)
		) 
	select array_agg(movieid) 
	from tbl2; 
$FUNCTION$;

-- проверим функцию
-- у нас есть пользователь с id=46 с 766 оценками фильмов, у него есть персечение с пользователем 65 в 146ти фильмах
-- для пользователя 65 рекомендацией будут фильмы, которые смотрел 46й, исключая пересечения, т.е. 766-146=620 штук
with temp as 
	(select userid, user_views, ur1, ur2, arr_res 
	from user_movies_agg right join common_user_views on userid=ur1) 
select ur2, array_length(diff_arr(user_views,arr_res),1) recomendations  
from temp 
where userid=46 and ur2=65; 
/*
 ur2 | recomendations 
-----+----------------
  65 |            620
(1 row)
*/
-- работает, проверим в обратную сторону - у пользователя 65 347 оценок, для него рекомендаций от 46го будут 347-146=201 фильм
with temp as 
	(select userid, user_views, ur1, ur2, arr_res 
	from user_movies_agg right join common_user_views on userid=ur1) 
select ur2, array_length(diff_arr(user_views,arr_res),1) recomendations  
from temp 
where userid=65 and ur2=46; 
/*
 ur2 | recomendations 
-----+----------------
  46 |            201
(1 row)
*/
-- ИТОГОВЫЙ ЗАПРОС БУДЕТ ТАКОВЫМ:
with temp as 
	(select userid, user_views, ur1, ur2, arr_res 
from user_movies_agg right join common_user_views on userid=ur1) 
select ur2 userid, 
	array_length(diff_arr(user_views,arr_res),1) cnt_recs, 
	diff_arr(user_views,arr_res) recomendations 
into films_recomendations
from temp; 

-- проверим на 1й записи
select * from films_recomendations limit 1;
/*
 userid | cnt_recs |recomendations                                                                                                                                 
     46 |      443 | {3984,2771,2021,1969,2468,1989,1300,4019,781,3177,4062,4008,858,3478,2758,2108,2331,176,2743,4047,4007,1307,3042,417,1894,1373,2469,1408,1673,1268,3868,2749,2686,1235,1594,1963,3985,2
657,2420,3703,2990,1649,1090,2259,349,2702,3071,2404,57,728,1978,2006,2065,508,3707,3206,2991,266,4066,2146,1287,2321,307,2352,4091,3941,3476,2301,1984,2734,446,86,2147,175,1979,2891,1653,1213,3098,2890,4
111,2,2770,1982,246,2917,3186,595,3072,2815,924,428,3285,1054,4034,2952,
2581,1381,3040,597,4104,3635,1449,164,2333,1952,2001,3328,1231,1276,110,3422,1959,58,3182,2976,2915,4003,2106,52,2687,2772,3394,3717,4031,1619,4010,1836,1197,101,3785,2369,1912,3142,1242,1848,1376,3702,3100,555,4041,1079,3479,3991,2150,3174,1447,1094,3498,3041,3526,1947,2245,3424,2457,2324,3101,3646,2109,4126,2989,1221,3844,2745,388,3421,1233,3178,2162,2151,2378,2928,1249,34,2427,1357,1747,2615,3431,1326,1084,3524,1956,1060,904,2383,2348,443,3682,3168,3105,2005,4086,2754,2329,39,3608,471,524,4103,2261,1185,1980,3689,3169,1674,300,2794,2368,2380,2058,1986,1441,1101,194,1271,1073,3688,3361,3499,1389,1735,2105,4005,293,1354,1120,1976,3267,3198,1257,3387,4109,2072,2396,3108,1179,1275,3148,3502,1810,2253,3014,1974,1977,3398,1983,431,3999,2819,1797,3505,1840,299,1272,541,3452,3135,2193,2871,1219,3160,4125,454,482,3197,838,2878,2795,1204,73,2372,2406,3653,3017,2792,1985,2376,2194,2413,4100,2122,1088,3939,1243,3129,3271,3259,2379,2145,1729,2381,1247,3695,562,1228,2947,233,1542,1914,1611,3556,497,2248,2950,3861,2474,1323,2405,1921,2320,2166,3418,3484,1600,3512,3704,2295,2677,994,2816,852,986,2903,1394,3102,1347,1246,319,3363,1873,2739,3961,1208,162,322,1610,1958,2600,3423,3060,2435,2422,2408,1220,3360,1466,3614,3273,2382,2966,2371,2247,3768,3683,4124,2450,2268,2289,2596,527,3543,3391,235,590,3074,147,2000,2671,2926,2336,412,3019,26,3252,1895,3317,3324,1960,232,1981,3708,2144,1186,17,1962,1784,4067,1147,3751,3690,2942,3286,1298,2968,574,1245,2282,1305,3347,1230,1446,45,3412,1375,1297,1304,1302,3157,2050,1293,36,2416,3006,3270,2064,1288,1207,265,3298,111,62,2305,3256,2375,1996,3962,2692,3408,4039,1225,1080,3388,1972,25,1188,1191,3489,1125,2902,4132,2460,3276}
(1 row)
*/

-- проверим 10 рекомендованных фильмов в исходных просморах пользователя
select 1 
from user_movies_agg 
where userid=46 and '{3984, 2771, 2021, 1969, 2468, 1989, 1300, 4019, 781, 3177}' && user_views;
/*
 ?column? 
----------
(0 rows)
*/
-- такие фильмы не найдены в библиотеке существующих просмотров пользователя 46, рекомендация работает

