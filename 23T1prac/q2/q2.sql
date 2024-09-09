-- COMP3311 23T1 Final Exam
-- Q2: ids of people with same name

-- replace this line with any helper views --
create or replace view help(name, id) as
select concat(given, ' ', family) as name, STRING_AGG(id::text, ','order by id) from customers group by name;

create or replace view q2(name,ids)
as
select name, id
from help
where id ~ ','
-- replace this line with your SQL code --
;

