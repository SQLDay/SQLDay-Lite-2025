# Years with more than 1 month in which Full Moon occurs twice.

FROM `bigquery-public-data.moon_phases.moon_phases`
|> WHERE phase_emoji = '🌕'   #|> WHERE phase = 'Full Moon'
|> EXTEND EXTRACT(YEAR FROM peak_datetime) AS year,
          EXTRACT(MONTH FROM peak_datetime) AS month

# Find months with 2 full moons.
|> AGGREGATE
      ARRAY_AGG(peak_datetime ORDER BY peak_datetime) AS peaks
   GROUP AND ORDER BY year, month
|> WHERE ARRAY_LENGTH(peaks) > 1

# Find years with 2 or more months with 2 full moons.
|> AGGREGATE
      ARRAY_AGG(STRUCT(month, peaks) ORDER BY month) AS peak_months
   GROUP AND ORDER BY year
|> WHERE ARRAY_LENGTH(peak_months) > 1

# Further analysis. Find those years where the second month
# was April.
# (Assume this requirement was not known at the beginning,
# otherwise we could filter the month above.)
# We just follow the query with more pipe operators.
|> WHERE EXISTS (
   FROM UNNEST(peak_months) AS year_peak_data
   |> WHERE month = 4
)
;



# Traditional syntax
SELECT * FROM (
  SELECT year,
         ARRAY_AGG(STRUCT(year, month, peaks) ORDER BY year_month) AS year_peak_months
  FROM (
    SELECT EXTRACT(YEAR FROM peak_datetime) AS year,
           EXTRACT(MONTH FROM peak_datetime) AS month,
           FORMAT_DATE('%Y-%m', peak_datetime) AS year_month,
           ARRAY_AGG(peak_datetime ORDER BY peak_datetime) AS peaks
    FROM `bigquery-public-data.moon_phases.moon_phases`
    WHERE phase_emoji = '🌕'
    GROUP BY year, month, year_month
    HAVING ARRAY_LENGTH(peaks) > 1
  ) aggregated
  GROUP BY year
  HAVING ARRAY_LENGTH(year_peak_months) > 1
)
WHERE EXISTS(SELECT 1
             FROM UNNEST(year_peak_months) AS year_peak_data
             WHERE month = 4)
ORDER BY year
;

