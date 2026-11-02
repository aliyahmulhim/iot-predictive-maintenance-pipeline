{{ 
    config(
        materialized='table',
        schema='gold'
    )
}}

with hourly AS (
    SELECT
        machine_key,
        DATE_TRUNC('hour', event_ts) AS hour_ts,

        -- temperature aggregations
        ROUND(AVG(temperature_c), 2) AS avg_temperature_c,
        ROUND(MIN(temperature_c), 2) AS min_temperature_c,
        ROUND(MAX(temperature_c), 2) AS max_temperature_c,

        -- vibration aggregations
        ROUND(AVG(vibration_mm_s), 3) AS avg_vibration_mm_s,
        ROUND(MIN(vibration_mm_s), 3) AS min_vibration_mm_s,
        ROUND(MAX(vibration_mm_s), 3) AS max_vibration_mm_s,

        -- pressure & RPM
        ROUND(AVG(pressure_kpa), 1) AS avg_pressure_kpa,
        ROUND(AVG(rpm), 0) AS avg_rpm,

        -- current
        ROUND(AVG(current_a), 2) AS avg_current_a,
        ROUND(MAX(current_a), 2) AS max_current_a,

        -- counts 
        COUNT(*) AS reading_count,
        COUNT_IF(temperature_c IS NULL) AS null_temperature_count
    FROM {{ ref('fct_sensor_readings') }}    
    GROUP BY 1, 2
)
