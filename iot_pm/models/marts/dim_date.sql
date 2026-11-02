{{
    config(
        materialized='table',
        schema='gold'
    )
}}

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2025-01-01' as date)",
        end_date="cast('2028-01-01' as date)" 
    ) }}
)

SELECT 
    CAST(date_day AS DATE) AS date_key,
    YEAR(date_day) AS year,
    QUARTER(date_day) AS quarter,
    MONTH(date_day) AS month,
    WEEKOFYEAR(date_day) AS week_of_year,
    DAYOFWEEK(date_day) AS day_of_week,
    DAYNAME(date_day) AS day_name,
    MONTHNAME(date_day) AS month_name,
    CASE WHEN DAYOFWEEK(date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_spine    