FROM `bigquery-public-data.imdb.title_basics`
|> WHERE title_type = 'tvSeries'
      AND start_year > 1990
      AND genres LIKE '%Comedy%'
|> INNER JOIN `bigquery-public-data.imdb.title_ratings` AS ratings USING(tconst)
|> WHERE ratings.average_rating > 8.5
      AND num_votes > 10000
|> ORDER BY average_rating DESC
|> SELECT tconst, primary_title, start_year, average_rating
|> LIMIT 20
