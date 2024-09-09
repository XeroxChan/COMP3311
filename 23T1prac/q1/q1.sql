-- COMP3311 23T1 Final Exam
-- Q1: suburbs with the most customers

-- replace this line with any helper views --
CREATE OR REPLACE view lc(lives_in, count) AS
select c.lives_in, count(cust.lives_in) from customers c JOIN customers cust on c.id = cust.id group by c.lives_in order by count(cust.lives_in) DESC;

create or replace view q1(suburb,ncust)
as
select lc.lives_in, count
From lc
where count = (select max(count) from lc)
;

