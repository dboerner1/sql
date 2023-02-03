/*
Question 1
Let's compare the combo genres "Rom-Com" and "Dramedy" by their
average rating (average of avg_vote) and # of movies. Only use
movies with at least 10,000 votes as part of this analysis.

Definitions:
"Rom-Com" = A movie with both "Comedy" and "Romance" in the genre
"Dramedy" = A movie with both "Comedy" and "Drama" in the genre

If a movie has "Comedy", "Romance" AND "Drama" in the genre, it should
count in both categories.

You will create a new field called "combo_genre" which contains either
"Rom-Com" or "Dramedy".

Provide the output sorted by "combo_genre" alphabetically.

Hint:  Calculate the two "combo_genre" in separate queries and UNION the results together
*/
SELECT
    'Rom-Com' AS combo_genre,
    ROUND(AVG(avg_vote), 2) AS avg_rating,
    COUNT(*) AS num_movies
FROM (
        SELECT
            avg_vote
        FROM movies
        WHERE genre ILIKE '%Romance%' AND genre ILIKE '%Comedy%'
        AND votes >= 10000
    ) romcoms
UNION ALL
SELECT
    'Dramedy' AS combo_genre,
    ROUND(AVG(avg_vote), 2) AS avg_rating,
    COUNT(*) AS num_movies
FROM (
        SELECT
            avg_vote
        FROM movies
        WHERE genre ILIKE '%Drama%' AND genre ILIKE '%Comedy%'
        AND votes >= 10000
    ) dramedies
ORDER BY combo_genre;
/*
Question 2
Provide a list of the top 10 movies (by votes) where the cast has at least
4 members and the cast consists only of actresses (no actors).

The columns you should report are "original_title", "avg_vote" and "votes",
all from the "movies" table.

Hint: Consider writing a subquery to filter to the
imdb_title_id of movies that fit this criteria.
*/
SELECT
    m.original_title AS original_title,
    m.avg_vote AS avg_vote,
    m.votes AS votes
FROM movies m
INNER JOIN (
    SELECT imdb_title_id,
           COUNT(CASE WHEN category = 'actor' THEN category ELSE NULL END)   AS num_actors,
           COUNT(CASE WHEN category = 'actress' THEN category ELSE NULL END) AS num_actresses
    FROM title_principals
    GROUP BY 1
    HAVING COUNT(CASE WHEN category = 'actor' THEN category ELSE NULL END) +
           COUNT(CASE WHEN category = 'actress' THEN category ELSE NULL END) >= 4
       AND COUNT(CASE WHEN category = 'actor' THEN category ELSE NULL END) = 0
) tp ON m.imdb_title_id = tp.imdb_title_id
ORDER BY 3 DESC
LIMIT 10;
/*
Question 3
What is the consensus worst movie for each production company?
Find the movie with the most votes but with avg_vote <= 5 for each production company.
Provide the top 10 movies ordered by votes (from highest to lowest)

Hint: Use an analytic function to find the top voted movie per production company
 */
SELECT
    *
FROM (
        SELECT
            original_title,
            production_company,
            avg_vote,
            votes,
            RANK() OVER (PARTITION BY production_company ORDER BY votes DESC) AS rank
        FROM movies
        WHERE
            avg_vote <= 5
         ) flops
WHERE rank = 1
ORDER BY votes DESC
LIMIT 10;
/*
Question 4
What was the longest gap between movies published by production company "Marvel Studios"?
Use "date_published" as the date.
Return the gap as a field called "gap_length" that is an Interval data type
calculated by using the AGE() function.
AGE() documentation can be found here: https://www.postgresql.org/docs/current/functions-datetime.html

Hint: Use an analytic function to align each Marvel movie with the movie
released immediately prior to it.
*/
SELECT
    *
FROM (
SELECT
    original_title,
    date_published,
    LAG(original_title, 1) OVER(ORDER BY date_published) AS prev_original_title,
    LAG(date_published, 1) OVER(ORDER BY date_published) AS prev_date_published,
    AGE(date_published::timestamp, LAG(date_published::timestamp, 1) OVER(ORDER BY date_published)) AS gap_length
FROM movies
WHERE
    production_company = 'Marvel Studios'
ORDER BY 5 DESC) marvel_movies
WHERE
    prev_original_title IS NOT NULL
LIMIT 1;
/*
Question 5
Of all Zoe Saldana movies (movies where she is listed in the actors column of the movies table),
what is the % of total worldwide gross income contributed by each movie?
Round the % to 2 decimal places, sort from highest % to lowest %,
and return the top 10.

Numerator = worlwide_gross_income for each Zoe Saldana movie
Denominator = total worlwide_gross_income for all Zoe Saldana movies

Filter out any movies with null worlwide_gross_income

Hint: Use an analytic function to place the total (denominator) on each row
to make the calculation easy
*/
SELECT
    original_title,
    ROUND(worldwide_gross_income * 100.0 / SUM(worldwide_gross_income) OVER (), 2) AS pct_total_gross_income
FROM (SELECT original_title,
             CAST(LTRIM(worlwide_gross_income, '$ ') AS NUMERIC) AS worldwide_gross_income
      FROM movies
      WHERE actors LIKE '%Zoe Saldana%'
        AND worlwide_gross_income IS NOT NULL
     ) all_saldana_movies
ORDER BY 2 DESC
LIMIT 10;