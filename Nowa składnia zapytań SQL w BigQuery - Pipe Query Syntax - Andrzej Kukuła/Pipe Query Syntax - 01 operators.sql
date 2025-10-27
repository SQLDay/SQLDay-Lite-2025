# Create a sample table and populate it with data.
CREATE OR REPLACE TABLE pqs.rect
OPTIONS (
  # I won't have to clean it up :-)
  EXPIRATION_TIMESTAMP = TIMESTAMP_ADD (CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
)
AS
  SELECT ['A','B','C','D','E','F','G','H','I','J'][OFFSET(CAST(FLOOR(RAND() * 10) AS INT64))] AS kind,
     CAST(FLOOR(RAND()*20)+1 AS INT64) AS r_width,
     CAST(FLOOR(RAND()*20)+1 AS INT64) as r_height
  FROM UNNEST(GENERATE_ARRAY(1,1000))
;



# This is the simplest query possible with pipe query syntax.
FROM pqs.rect

|> SELECT *     # implicit, no-op
;




# Let's explore the most common operators.
FROM pqs.rect
|> EXTEND r_width * r_height AS area
|> RENAME r_width AS width, r_height AS height
|> EXTEND LEAST(width, height) AS shorter_side,
          GREATEST(width, height) AS longer_side
|> DROP width, height

|> WHERE area > 50
|> ORDER BY longer_side DESC
|> LIMIT 50

|> EXTEND 2*shorter_side + 2*longer_side AS perimeter
|> AGGREGATE SUM(area) AS sum_areas, 
             SUM(perimeter) AS sum_perimeter,
             COUNT(*) AS num_rectangles
   GROUP BY kind
#|> WHERE shorter_side < 10  # this column is not available anymore.

|> ORDER BY sum_areas DESC
|> LIMIT 5

# Now see the execution graph and how number of stages differs from
# the amount of operators in the query.

|> EXTEND
   RANK() OVER (ORDER BY sum_perimeter DESC) AS pos
|> WHERE sum_perimeter > 300  # this used to be HAVING
|> AS rect_rowset             # only when needed, useful when doing joins

|> WHERE pos > 1              # yet another WHERE, because why not

|> ORDER BY pos

# You can put an explicit SELECT if you feel that you lost track
# of the shape of the data.
# Note: this is entirely optional. If the list of columns resembles
# current shape of the rowset, SELECT will be a no-op.

# It may be used for column reordering (if the order matters to recipient).
|> SELECT pos, num_rectangles, sum_areas
;


# The pipe operator can be added to the end of any valid query.
# The following wouldn't be possible using standard syntax (no WHERE
# after ORDER BY).

SELECT * FROM pqs.rect
ORDER BY kind

|> WHERE kind IN ('A', 'B', 'C')
|> AS ext
|> WHERE r_width > (
   FROM pqs.rect AS int
   |> WHERE int.kind = ext.kind            # a bit of correlation
   |> AGGREGATE AVG(r_width) AS avg_width
)
# The query has been de-correlated (changed into JOIN)
# and the sort was disregarded by the engine.

|> AGGREGATE SUM(r_width) AS sum_width,
             SUM(r_height) AS sum_height
   GROUP AND ORDER BY kind

# End of demo
