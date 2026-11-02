{{
    config(
        materialized='table',
        schema='gold'
    )
}}

WITH daily AS (
    SELECT 
        machine_key,
        DATE(hour_ts) AS date_key,
        AVG(avg_vibration_mm_s) AS vib_avg,
        MAX(max_vibration_mm_s) AS vib_max,
        AVG(avg_temperature_c) AS temp_avg,
        AVG(avg_current_a) AS current_avg,
        SUM(reading_count) AS reading_count
    FROM {{ ref('fct_sensor_readings_hourly') }}
    GROUP BY 1,2    
),

windowed AS (
    SELECT 
        *,
        -- vibration rolling windows
        AVG(vib_avg) OVER (
            PARTITION BY machine_key ORDER BY date_key
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW 
        ) AS vib_7d_avg,

        AVG(vib_avg) OVER (
            PARTITION BY machine_key ORDER BY date_key
            ROWS BETWEEN 29 PRECEDING AND 7 PRECEDING
        ) AS vib_baseline,

        STDDEV(vib_avg) OVER (
            PARTITION BY machine_key ORDER BY date_key
            ROWS BETWEEN 29 PRECEDING AND 7 PRECEDING
        ) AS vib_std,

        -- temp rolling windows
        AVG(temp_avg) OVER (
            PARTITION BY machine_key ORDER BY date_key
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS temp_7d_avg,

        AVG(temp_avg) OVER (
             PARTITION BY machine_key ORDER BY date_key
            ROWS BETWEEN 29 PRECEDING AND 7 PRECEDING  
        ) AS temp_baseline,

        STDDEV(temp_avg) OVER (
            PARTITION BY machine_key ORDER BY date_key
            ROWS BETWEEN 29 PRECEDING AND 7 PRECEDING
        ) AS temp_std
    FROM daily
),

scored AS (
    SELECT 
        *,
        -- Robust z-score -> floor the std to avoid explosion
        CASE
            WHEN vib_std IS NOT NULL THEN 
                (vib_avg - vib_baseline) / GREATEST(vib_std, 0.1) --floor
            ELSE 0
        END AS vib_zscore,
        CASE
            WHEN temp_std IS NOT NULL THEN 
                (temp_avg - temp_baseline) / GREATEST(temp_std, 0.5) --floor
            ELSE 0
        END AS temp_zscore   
    FROM windowed        
),

final AS (
    SELECT 
        machine_key,
        date_key,
        vib_avg,
        vib_max,
        temp_avg,
        current_avg,
        reading_count,
        ROUND(vib_7d_avg, 3) AS vib_7d_avg,
        ROUND(vib_baseline, 3) AS vib_baseline,
        ROUND(vib_std, 3) AS vib_std,
        ROUND(temp_7d_avg, 2) AS temp_7d_avg,
        ROUND(temp_baseline, 2) AS temp_baseline,
        ROUND(vib_zscore, 2) AS vib_zscore,
        ROUND(temp_zscore, 2) AS temp_zscore,

        -- health risk level (high-medium-low)
        CASE 
            WHEN GREATEST(COALESCE(vib_zscore, 0), COALESCE(temp_zscore, 0)) >=3 THEN 'HIGH'
            WHEN GREATEST(COALESCE(vib_zscore, 0), COALESCE(temp_zscore, 0)) >=2 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS health_risk_level   
    FROM scored        
)

SELECT * FROM final