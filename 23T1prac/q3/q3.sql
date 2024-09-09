-- COMP3311 23T1 Final Exam
-- Q3: show branches where
-- *all* customers who hold accounts at that branch
-- live in the suburb where the branch is located

-- replace this line with any helper views --
CREATE OR REPLACE VIEW HELPER(bid,blocate, cid, clives) as
select b.id, b.location, c.id, c.lives_in from branches b JOIN accounts a ON a.held_at = b.id JOIN held_by h on h.account = a.id JOIN customers c on c.id = h.customer;

--create or replace view q3(branch)
--as
-- replace this line with your SQL code --
--;
