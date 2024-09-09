-- COMP3311 24T1 Ass2 ... SQL helper Views/Functions
-- Add any views or functions you need into this file
-- Note: it must load without error into a freshly created Pokemon database

-- The `dbpop()` function is provided for you in the dump file
-- This is provided in case you accidentally delete it

DROP TYPE IF EXISTS Population_Record CASCADE;
CREATE TYPE Population_Record AS (
	Tablename Text,
	Ntuples   Integer
);

CREATE OR REPLACE FUNCTION DBpop()
    RETURNS SETOF Population_Record
    AS $$
        DECLARE
            rec Record;
            qry Text;
            res Population_Record;
            num Integer;
        BEGIN
            FOR rec IN SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename LOOP
                qry := 'SELECT count(*) FROM ' || quote_ident(rec.tablename);

                EXECUTE qry INTO num;

                res.tablename := rec.tablename;
                res.ntuples   := num;

                RETURN NEXT res;
            END LOOP;
        END;
    $$ LANGUAGE plpgsql
;

--
-- Example Views/Functions
-- These Views/Functions may or may not be useful to you.
-- You may modify or delete them as you see fit.
--

-- `Move_Learning_Info`
-- The `Learnable_Moves` table is a relation between Pokemon, Moves, Games and Requirements.
-- As it just consists of foreign keys, it is not very easy to read.
-- This view makes it easier to read by displaying the names of the Pokemon, Moves and Games instead of their IDs.
CREATE OR REPLACE VIEW Move_Learning_Info(Pokemon, Move, Game, Requirement) AS
    SELECT
        P.Name,
        M.Name,
        G.Name,
        R.Assertion
    FROM
        Learnable_Moves AS L
        JOIN Pokemon AS P
        ON Learnt_By = P.ID
        JOIN Games AS G
        ON Learnt_In = G.ID
        JOIN Moves AS M
        ON Learns = M.ID
        JOIN Requirements AS R
        ON Learnt_When = R.ID
;

-- `Super_Effective`
-- This function takes a type name and
-- returns a set of all types that it is super effective against (multiplier > 100)
-- eg Water is super effective against Fire, so `Super_Effective('Water')` will return `Fire` (amongst others)
CREATE OR REPLACE FUNCTION Super_Effective(_Type Text)
    RETURNS SETOF Text
    AS $$
        SELECT
            B.Name
        FROM
            Types AS A
            JOIN Type_Effectiveness AS E
            ON A.ID = E.Attacking
            JOIN Types AS B
            ON B.ID = E.Defending
        WHERE
            A.Name = _Type
            AND
            E.Multiplier > 100
    $$ LANGUAGE SQL
;

--
-- Your Views/Functions Below Here
-- Remember This file must load into a clean Pokemon database in one pass without any error
-- NOTICEs are fine, but ERRORs are not
-- Views/Functions must be defined in the correct order (dependencies first)
-- eg if my_supper_clever_function() depends on my_other_function() then my_other_function() must be defined first
-- Your Views/Functions Below Here
--

------------------------------------------------------------------------------------
--
--                                      Q1 helper sql
--
------------------------------------------------------------------------------------
--Helper view to obtain number of pokemon in each region and game
CREATE OR REPLACE VIEW Numbers_of_Pokemon(Region, Game, Num_Pokemon) AS
SELECT games.region,
       games.name,
       count(pokedex.national_id)
FROM games
INNER JOIN pokedex ON pokedex.game = games.id
GROUP BY games.region,
         games.name
ORDER BY games.region,
         games.name
;
--Helper view to obtain number of locations in each region and game
CREATE OR REPLACE VIEW Numbers_of_Locations(Region, Game, Num_Locations) AS
SELECT games.region,
       games.name,
       count(locations.id)
FROM games
INNER JOIN locations ON locations.appears_in = games.id
GROUP BY games.region,
         games.name
ORDER BY games.region,
         games.name
;
--Helper view to combine informations from the two help views in one
CREATE OR REPLACE VIEW Numbers_of_PL(Region, Game, Num_Pokemon, Num_locations) AS
SELECT np.region,
       np.game,
       np.num_pokemon,
       nl.num_locations
FROM numbers_of_pokemon np
JOIN numbers_of_locations nl ON np.region = nl.region
AND np.game = nl.game
ORDER BY np.region,
         np.game,
         np.num_pokemon,
         nl.num_locations
;
------------------------------------------------------------------------------------
--
--                                      Q2 helper sql
--
------------------------------------------------------------------------------------
--function to get the pokemon_id
CREATE OR REPLACE FUNCTION Pokemon_to_Id(pokemon_name TEXT) RETURNS TABLE(Id pokemon_id)
AS $$
SELECT pokemon.id
FROM pokemon
WHERE pokemon.name = pokemon_name
$$ LANGUAGE SQL
;

--Function to get everything else
CREATE OR REPLACE FUNCTION Q2(pk_id pokemon_id) RETURNS TABLE(Game_region TEXT, Game_name TEXT, Location_name TEXT, Encounter_rarity Probability, Encounter_levels closed_range, Inverted boolean, Requirements_id INTEGER, Requirements TEXT)
AS $$
SELECT g.region,
       g.name,
       l.name,
       e.rarity,
       e.levels,
       er.inverted,
       e.id,
       STRING_AGG(distinct(r.assertion), ', ' order by r.assertion)
FROM locations l
JOIN games g ON l.appears_in = g.id
JOIN encounters e ON e.occurs_at = l.id
JOIN encounter_requirements er ON er.encounter = e.id
JOIN requirements r ON r.id = er.requirement
WHERE e.occurs_with = pk_id
GROUP BY g.region,
	 g.name,
	 l.name,
	 e.rarity,
	 e.levels,
	 er.inverted,
	 e.id
ORDER BY g.region,
         g.name,
         l.name,
         e.rarity,
         e.levels
$$ LANGUAGE SQL
;
------------------------------------------------------------------------------------
--
--                                      Q4 helper sql
--
------------------------------------------------------------------------------------

--Get pokemon first and second type
CREATE OR REPLACE FUNCTION Get_Pokemon_Type(Pokemon_Name TEXT) RETURNS TABLE(Pokemon_Name TEXT, First_type Text, Second_type Text)
AS $$
SELECT p.name,
       t1.name,
       t2.name
FROM pokemon p
LEFT JOIN types t1 ON t1.id = p.first_type
LEFT JOIN types t2 ON t2.id = p.second_type
WHERE p.name = Pokemon_Name
$$ LANGUAGE SQL
;

--Function to get all the moves the pokemon can use with power no 0, requirements are ordered by requirement_id
CREATE OR REPLACE FUNCTION MOVE_TO_USE(Game_Name  TEXT, Pokemon_Name TEXT) RETURNS TABLE(Move_Name TEXT, Move_Requirement TEXT, Move_Power INTEGER, Move_Type TEXT)
AS $$
SELECT sub.move AS Move_Name,
 ARRAY_TO_STRING(ARRAY_AGG(sub.requirement
                           ORDER BY sub.min_r_id), ', ') AS Move_Requirement,
 sub.power AS Move_Power,
 sub.type_name AS Move_Type
FROM
  (SELECT DISTINCT ON (mli.move,
                       r.id) mli.move,
                      r.id AS min_r_id,
                      mli.requirement,
                      m.power,
                      t.name AS type_name
   FROM move_learning_info mli
   JOIN moves m ON mli.move = m.name
   JOIN types t ON m.of_type = t.id
   JOIN requirements r ON r.assertion = mli.requirement
   WHERE mli.pokemon = Pokemon_Name
     AND mli.game = Game_Name
     AND m.power IS NOT NULL
   ORDER BY mli.move,
            r.id) sub
GROUP BY sub.move,
         sub.power,
         sub.type_name
ORDER BY Move_Name
$$ LANGUAGE SQL
;

--View containing the name of atk_type and def_type and the effectiveness
CREATE OR REPLACE VIEW ATK_DEF_TYPE_EFFECTIVENESS(ATK_TYPE, DEF_TYPE, MULTIPLIER) AS
SELECT t1.name,
       t2.name,
       te.multiplier
FROM type_effectiveness te
JOIN types t1 ON te.attacking = t1.id
JOIN types t2 ON te.defending = t2.id
;
