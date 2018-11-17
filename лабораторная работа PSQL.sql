---------------------------- Данильченко В.Н. ------------------------------------
-------------------------- Лабораторна работа ------------------------------------

-- cоздадим таблицу отделений и заполним значениями
create table Departments (id integer, name varchar)

insert into Departments values (1, 'Therapy'), (2, 'Neurology'), (3, 'Cardiology'), (4, 'Gastroenterology'), (5, 'Hematology'), (6, 'Oncology');

-- cоздадим таблицу информации о сотрудниках и заполним значениями
create table Employee (id integer, department_id integer, chief_doc_id integer, name varchar, num_public integer);

insert into Employee values ('1', '1', '1', 'Kate', 4), ('2', '1', '1', 'Lidia', 2), ('3', '1', '1', 'Alexey', 1), ('4', '1', '2', 'Pier', 7), ('5', '1', '2', 'Aurel', 6),
('6', '1', '2', 'Klaudia', 1), ('7', '2', '3', 'Klaus', 12), ('8', '2', '3', 'Maria', 11), ('9', '2', '4', 'Kate', 10), ('10', '3', '5', 'Peter', 8),
('11', '3', '5', 'Sergey', 9), ('12', '3', '6', 'Olga', 12), ('13', '3', '6', 'Maria', 14), ('14', '4', '7', 'Irina', 2), ('15', '4', '7', 'Grit', 10),
('16', '4', '7', 'Vanessa', 16), ('17', '5', '8', 'Sascha', 21), ('18', '5', '8', 'Ben', 22), ('19', '6', '9', 'Jessy', 19), ('20', '6', '9', 'Ann', 18);

-- посмотрим все связи(таблица маленькая, норм)
select * from Employee emp left join Departments dep on emp.department_id=dep.id;

--Вывести список названий департаментов и количество главных врачей в каждом из этих департаментов
select dep.name, 
	count(distinct emp.chief_doc_id) chief_doctor 
from Departments dep left join Employee emp on dep.id=emp.department_id 
group by dep.name;
/*
      name       | chief_doctor 
------------------+--------------
 Cardiology       |            2
 Gastroenterology |            1
 Hematology       |            1
 Neurology        |            2
 Oncology         |            1
 Therapy          |            2
(6 rows)

*/

-- Выведем список департамент id в которых работаю 3 и более сотрудника
select dep.id 
from Departments dep left join Employee emp on dep.id=emp.department_id 
group by dep.id 
having count(distinct emp.id)>=3;
/*
 id 
----
  1
  2
  3
  4
(4 rows)
*/
-- Выведем список департамент id с максимальным количеством публикаций
with T as (select dep.id, dep.name, sum(emp.num_public) publications 
	from Departments dep left join Employee emp on dep.id=emp.department_id 
	group by dep.id, dep.name) 
select id 
from T 
where publications=(select max(publications) from T);
/*
 id 
----
  5
  3
(2 rows)
*/
--Выведем список имен сотрудников и департаментов с минимальным количеством в своем департаментe
with T as (select dep.id, 
		dep.name dep_name, 
		emp.num_public, 
		emp.name emp_name, 
		min(emp.num_public) over(partition by dep.id) min_publications 
	from Departments dep left join Employee emp on dep.id=emp.department_id 
	group by dep.id, dep.name, emp.num_public, emp.name) 
select emp_name, 
	dep_name 
from T 
where num_public=min_publications 
group by dep_name, emp_name;
/*
 emp_name |     dep_name     
----------+------------------
 Peter    | Cardiology
 Irina    | Gastroenterology
 Sascha   | Hematology
 Kate     | Neurology
 Ann      | Oncology
 Alexey   | Therapy
 Klaudia  | Therapy
(7 rows)
*/
-- Выведем список названий департаментов и среднее количество публикаций для тех департаментов, в которых работает более одного главного врача (округлю до сотых)
select dep.name, 
	round(avg(emp.num_public),2) avg_pubs 
from Departments dep left join Employee emp on dep.id=emp.department_id 
where dep.id in (select dep.id 
		from Departments dep left join Employee emp on dep.id=emp.department_id 
		group by dep.id 
		having count(distinct emp.chief_doc_id)>1) 
group by dep.name;
/*
    name    | avg_pubs 
------------+----------
 Cardiology |    10.75
 Therapy    |     3.50
 Neurology  |    11.00
(3 rows)
*/
