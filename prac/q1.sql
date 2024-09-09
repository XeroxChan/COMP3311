-- COMP3311 23T3 Final Exam
-- Q1: oldest Fun Run participants

-- replace this line with any helper views --
CREATE OR REPLACE view ages(person, event, held, age) AS 
select p.name, e.name, e.held_on,(e.held_on - p.d_o_b) / 365 AS age from people p JOIN participants part on p.id = part.person_id JOIN events e ON e.id = part.event_id;

CREATE OR REPLACE view q1(person, age, event) AS 
select person, age, substr(held::text,1,4)||' '||event from ages where age = (select max(age) from ages)
;
