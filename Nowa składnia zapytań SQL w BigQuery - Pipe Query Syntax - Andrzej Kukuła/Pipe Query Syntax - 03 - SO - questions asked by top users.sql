# Find number of answered questions asked by top 10 users on StackOverflow, per year.

WITH top_10_users AS (
  FROM `bigquery-public-data.stackoverflow.users` AS users
  |> WHERE creation_date < '2010-01-01' AND up_votes > 100
  |> ORDER BY reputation DESC
  |> LIMIT 10
  |> SELECT *   # implicit, not required
)

FROM `bigquery-public-data.stackoverflow.posts_questions` AS questions
# First we filter data - this matches our conceptual model of the query.
# 3 WHEREs in a row! Can be one with "AND" instead. Flattened by the optimizer.
|> WHERE questions.creation_date < TIMESTAMP '2010-01-01'
|> WHERE questions.view_count > 10
|> WHERE answer_count > 0
# JOIN done only now - how much easier to express mental query model and
# desired calculations - and to understand it!
|> INNER JOIN top_10_users AS users ON questions.owner_user_id = users.id

|> AGGREGATE COUNT(*) as question_count 
   GROUP AND ORDER BY EXTRACT(year FROM questions.creation_date) AS creation_year

;
