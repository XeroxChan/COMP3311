CREATE OR REPLACE VIEW finishers(person, event, date, time) AS
select p.name, e.name, e.held_on, r.at_time from people p JOIN participants pp on p.id = pp.person_id JOIN events e on e.id = pp.event_id JOIN checkpoints c on e.route_id = c.route_id JOIN reaches r on partic_id = pp.id and chkpt_id = c.id where c.ordering = (select max(ordering) from checkpoints where route_id = e.route_id);


CREATE OR REPLACE VIEW Q2(event, date, person, time) AS
select event, date, person, time from finishers f where f.time = (select min(q.time) from finishers q where q.event = f.event and q.date = f.date)
order by date, person
;
