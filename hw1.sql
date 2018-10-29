SELECT ('ФИО: Данильченко Вадим');
-------------------- Домашнее заданиче №2 ------------------------
--------------------- Данильченко Вадим --------------------------

--1. 10 первых записей
select * 
from ratings 
limit 10;

select * 
from links 
where imdbid like '%42' and movieid between 100 and 1000
limit 10;

--2. JOIN
select imdbid 
from links l inner join ratings r 
  on l.movieid=r.movieid where rating=5
limit 10;


--3. Агрегация
select count(l.movieid) 
from links l left join ratings r 
	on l.movieid=r.movieid 
where r.rating is null;

select userid 
from ratings 
group by userid 
having avg(rating)>3.5 
limit 10;

--4. Иерархические запросы
select imdbid 
from links l inner join ratings r 
  on l.movieid=r.movieid 
group by l.imdbid 
having avg(r.rating)>3.5 
limit 10;

with users as (
  select userid 
  from ratings 
  group by userid 
  having count(*)>10) 
select userid, avg(rating) 
from ratings 
where userid in (
  select * from users) 
group by userid 
limit 10;


