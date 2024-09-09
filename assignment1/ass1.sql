/*
    COMP3311 24T1 Assignment 1
    IMDB Views, SQL Functions, and PlpgSQL Functions
    Student Name: <Yuet Yat Chan>
    Student ID: <z5289835>
    Codes formatted by SQLFormat.org (https://sqlformat.org)
*/

-- Question 1 --

/**
    Write a SQL View, called Q1, that:
    Retrieves the 10 movies with the highest number of votes.
*/
CREATE OR REPLACE VIEW Q1(Title, Year, Votes) AS
SELECT m.primary_title,
       m.release_year,
       m.votes
FROM movies m
WHERE votes IS NOT NULL
ORDER BY votes DESC
LIMIT 10 ;

-- Question 2 --

/**
    Write a SQL View, called Q2(Name, Title), that:
    Retrieves the names of people who have a year of death recorded in the database
    and are well known for their work in movies released between 2017 and 2019.
*/
CREATE OR REPLACE VIEW Q2(Name, Title) AS
SELECT p.name,
       m.primary_title
FROM people p
INNER JOIN principals prin ON prin.person = p.id
INNER JOIN movies m ON m.id = prin.movie
WHERE p.death_year IS NOT NULL
  AND m.release_year BETWEEN 2017 AND 2019
ORDER BY p.name ASC ;

-- Question 3 --

-- helper view to group all movies by genres, calculate the average score
CREATE OR REPLACE VIEW genre_avg_scores(Genre, Average) AS
SELECT g.name,
       ROUND(AVG(m.score), 2)
FROM genres g
INNER JOIN movies_genres mg ON mg.genre = g.id
INNER JOIN movies m ON mg.movie = m.id
WHERE m.score IS NOT NULL
GROUP BY g.name ;

-- helper view to count genres of movie
CREATE OR REPLACE VIEW genre_count AS
SELECT g.name,
       count(mg.genre)
FROM genres g
INNER JOIN movies_genres mg ON mg.genre = g.id
GROUP BY g.name ;

/**
    Write a SQL View, called Q3(Name, Average), that:
    Retrieves the genres with an average rating not less than 6.5 and with more than 60 released movies.
*/
CREATE OR REPLACE VIEW Q3(Name, Average) AS
SELECT gas.genre,
       gas.average
FROM genre_avg_scores gas
INNER JOIN genre_count gc ON gas.genre = gc.name
WHERE gas.average > 6.5
  AND gc.count > 60
ORDER BY gas.average DESC,
         gas.genre ;


-- Question 4 --

-- helper view to uniq movies from region
CREATE OR REPLACE VIEW unique_movies AS
SELECT re.movie,
       m.runtime,
       re.region
FROM movies m
INNER JOIN releases re ON re.movie = m.id
WHERE m.runtime IS NOT NULL ;

--helper view showing total movie runtime for each region
CREATE OR REPLACE VIEW total_runtime AS
SELECT u.region,
       (AVG(m.runtime)) AS average
FROM unique_movies u
INNER JOIN movies m ON u.movie = m.id
WHERE m.runtime IS NOT NULL
GROUP BY u.region
ORDER BY (avg(m.runtime)) DESC ;

--helper view to calculate the average runtime of all movies
CREATE OR REPLACE VIEW average_runtime_all AS
SELECT (AVG(runtime)) AS AVG
FROM movies ;

--helper view for final result but unrounded
CREATE OR REPLACE VIEW raw_num AS
SELECT t.region,
       t.average
FROM total_runtime t
WHERE t.average >
    (SELECT a.avg
     FROM average_runtime_all a) ;
     
/**
    Write a SQL View, called Q4(Region, Average), that:
    Retrieves the regions with an average runtime greater than the average runtime of all movies.
*/
CREATE OR REPLACE VIEW Q4(Region, Average) AS
SELECT ra.region,
       ROUND(ra.average)
FROM raw_num ra
ORDER BY ROUND(ra.average) DESC, ra.region ;

-- Question 5 --

/**
    Write a SQL Function, called Q5(Pattern TEXT) RETURNS TABLE (Movie TEXT, Length TEXT), that:
    Retrieves the movies whose title matches the given regular expression,
    and displays their runtime in hours and minutes.
*/
CREATE OR REPLACE FUNCTION Q5(Pattern TEXT) RETURNS TABLE (Movie TEXT, LENGTH Text)
AS $$
	SELECT
		m.primary_title AS movie,
		Cast(m.runtime / 60 AS 	VARCHAR) || ' Hours ' || Cast(m.runtime % 60 AS VARCHAR) || ' Minutes'
	FROM
		movies m
	WHERE
		primary_title ~ Pattern
		AND m.runtime IS NOT NULL
	ORDER BY
		m.primary_title
$$ LANGUAGE sql ;

-- Question 6 --

--helper view to get release_year and genre
CREATE OR REPLACE VIEW movie_year_genre AS
SELECT m.release_year,
       g.name AS genre
FROM movies m
INNER JOIN movies_genres mg ON m.id = mg.movie
INNER JOIN genres g ON mg.genre = g.id
WHERE m.release_year IS NOT NULL ;


/**
    Write a SQL Function, called Q6(GenreName TEXT) RETURNS TABLE (Year Year, Movies INTEGER), that:
    Retrieves the years with at least 10 movies released in a given genre.
*/
CREATE OR REPLACE FUNCTION Q6(GenreName TEXT) RETURNS TABLE (Year Year, Movies INTEGER)
AS $$
	WITH num_year_genre AS (
		SELECT release_year, 
		       count(release_year) 
		FROM movie_year_genre 
		WHERE genre = GenreName 
		GROUP BY release_year
	)
        SELECT nyg.release_year, 
               nyg.count 
        FROM num_year_genre nyg 
        WHERE nyg.count > 10 
        ORDER BY nyg.count DESC, 
        	 nyg.release_year DESC ;
$$ LANGUAGE sql ;


-- Question 7 --

--helper function to get actors from specific movie and their roles
CREATE OR REPLACE FUNCTION actor_with_multi(MovieName TEXT) RETURNS TABLE(actor TEXT, count INT)
AS $$
	SELECT p.name,
	       count(pro.name)
	FROM people p
	INNER JOIN ROLES r ON r.person = p.id
	INNER JOIN professions pro ON pro.id = r.profession
	INNER JOIN movies m ON m.id = r.movie
	WHERE m.primary_title = moviename
	GROUP BY p.name ;
$$ LANGUAGE sql ;

/**
    Write a SQL Function, called Q7(MovieName TEXT) RETURNS TABLE (Actor TEXT), that:
    Retrieves the actors who have played multiple different roles within the given movie.
*/
CREATE OR REPLACE FUNCTION Q7(MovieName TEXT) RETURNS TABLE (Actor TEXT)
AS $$
	SELECT actor
	FROM
	  (SELECT *
	   FROM actor_with_multi(moviename))
	WHERE COUNT > 1
	ORDER BY actor ASC ;
$$ LANGUAGE sql ;




-- Question 8 --

--helper function to check if movie exist
CREATE OR REPLACE FUNCTION find_movie(MovieName TEXT) RETURNS INT
AS $$	
	SELECT count(id)
	FROM movies
	WHERE primary_title = moviename
	GROUP BY id ;
$$ LANGUAGE sql ;
	
--helper function to collect releases of movie
CREATE OR REPLACE FUNCTION movie_releases(MovieName TEXT) RETURNS TABLE (Release_id INT) 
AS $$
	SELECT r.id
	FROM releases r
	INNER JOIN movies m ON m.id = r.movie
	WHERE m.primary_title = MovieName ;
$$ LANGUAGE sql ;

/**
    Write a SQL Function, called Q8(MovieName TEXT) RETURNS TEXT, that:
    Retrieves the number of releases for a given movie.
    If the movie is not found, then an error message should be returned.
*/

CREATE OR REPLACE FUNCTION Q8(MovieName TEXT) RETURNS TEXT
AS $$
DECLARE output text ;
	numRows INT ;
BEGIN
	output := '' ;
	IF (SELECT find_movie(MovieName)) IS NULL THEN
		output := 'Movie ' || '"' || MovieName || '" not found' ;
	ELSE
		numRows := (SELECT count(*) FROM (SELECT * FROM movie_releases(MovieName)));
		IF numRows = 0 THEN
			output := 'No releases found for "' || MovieName || '"' ;
		ELSE
			output := 'Release count: ' || numRows ;
		END IF ;
	END IF ;
	RETURN output ;
END ;
$$ LANGUAGE plpgsql ;

-- Question 9 --

--helper function to get cast for certain movie
CREATE OR REPLACE FUNCTION movie_cast(MovieName TEXT) RETURNS TABLE(person_name TEXT, played TEXT, movie TEXT)
AS $$
	SELECT p.name,
	       r.played,
	       m.primary_title
	FROM people p
	INNER JOIN ROLES r ON r.person = p.id
	INNER JOIN movies m ON m.id = r.movie
	WHERE m.primary_title = MovieName ;
$$ LANGUAGE sql ;

--helper function to turn columns into string
CREATE OR REPLACE FUNCTION cast_concat(MovieName TEXT) RETURNS SETOF TEXT
AS $$
	SELECT CONCAT('"', person_name, '"', ' played ', '"', played, '"', ' in ', '"', movie, '"')
	FROM
	  (SELECT *
	   FROM movie_cast(MovieName)) ;
$$ LANGUAGE sql ;



--helper function to get crew for certain movie
CREATE OR REPLACE FUNCTION movie_crew(MovieName TEXT) RETURNS TABLE(person_name TEXT, movie TEXT, job TEXT)
AS $$
	SELECT p.name,
	       m.primary_title,
	       pro.name
	FROM people p
	INNER JOIN credits c ON c.person = p.id
	INNER JOIN movies m ON m.id = c.movie
	INNER JOIN professions pro ON pro.id = c.profession
	WHERE m.primary_title = MovieName ;
$$ LANGUAGE sql ;

--helper function to turn columns into string
CREATE OR REPLACE FUNCTION crew_concat(MovieName TEXT) RETURNS SETOF TEXT
AS $$
	SELECT CONCAT('"', person_name, '"', ' worked on ', '"', movie, '"', ' as a ', job)
	FROM
	  (SELECT *
	   FROM movie_crew(MovieName)) ;
$$ LANGUAGE sql ;


/**
    Write a SQL Function, called Q9(MovieName TEXT) RETURNS SETOF TEXT, that:
    Retrieves the Cast and Crew of a given movie.
*/
CREATE OR REPLACE FUNCTION Q9(MovieName TEXT) RETURNS SETOF TEXT
AS $$
DECLARE r record ;
BEGIN
	for r in (select * from cast_concat(MovieName))
	loop
		return next r ;
	end loop ;
	for r in (select * from crew_concat(MovieName))
	loop
		return next r ;
	end loop ;
	return ;	
END ;
$$ LANGUAGE plpgsql ;

-- Question 10 --

--helper function to create top movies from a region
CREATE OR REPLACE FUNCTION top_movies(MovieRegion CHAR(4)) RETURNS TABLE (release_year INTEGER, Movie TEXT, Genre TEXT, Principal TEXT, rating_rank INTEGER)
AS $$
	SELECT m.release_year,
	       m.primary_title,
	       STRING_AGG(distinct(g.name), ', '
		          ORDER BY g.name ASC),
	       STRING_AGG(distinct(p.name), ', '),
	       RANK() OVER (PARTITION BY m.release_year
		            ORDER BY m.score DESC)
	FROM movies m
	LEFT JOIN movies_genres mg ON mg.movie = m.id
	LEFT JOIN genres g ON g.id = mg.genre
	LEFT JOIN principals prin ON prin.movie = m.id
	LEFT JOIN people p ON p.id = prin.person
	LEFT JOIN releases r ON r.movie = m.id
	WHERE r.region = MovieRegion
	  AND m.release_year IS NOT NULL
	  AND m.score IS NOT NULL
	GROUP BY m.release_year,
		 m.primary_title,
		 m.score;
$$ LANGUAGE sql ;



/**
    Write a PLpgSQL Function, called Q10(MovieRegion CHAR(4)) RETURNS TABLE (Year INTEGER, Best_Movie TEXT, Movie_Genre Text,Principals TEXT), that:
    Retrieves the list of must-watch movies for a given region, year by year.
*/
CREATE OR REPLACE FUNCTION Q10(MovieRegion CHAR(4)) RETURNS TABLE (Year INTEGER, Best_Movie TEXT, Movie_Genre TEXT, Principals TEXT) 
AS $$
BEGIN
	RETURN QUERY
	SELECT release_year,
	       movie,
	       genre,
	       principal
	FROM
	  (SELECT *
	   FROM top_movies(MovieRegion))
	WHERE rating_rank = 1
	ORDER BY release_year DESC,
		 movie ;
	RETURN ;
END ;
$$ LANGUAGE plpgsql ;


