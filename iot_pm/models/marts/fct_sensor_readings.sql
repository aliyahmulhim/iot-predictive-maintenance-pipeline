{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with staging AS (
    select * from {{ ref('stg_sensor_readings') }}
),

deduplicated AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY machine_id, event_ts
            ORDER BY _processed_at DESC
        ) AS rn
    FROM staging    
),

cleaned AS (
    SELECT
        machine_id,
        event_ts,
        event_date,
        CASE WHEN temperature_c = 999.0 then NULL ELSE temperature_c END AS temperature_c,
        vibration_mm_s,
        pressure_kpa,
        rpm,
        current_a,
        firmware_version,
        _processed_at
    FROM deduplicated
    WHERE rn = 1   
        AND temperature_c IS NOT NULL
        AND temperature_c !=999.0 
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['c.machine_id', 'c.event_ts']) }} as sensor_reading_id,
        m.machine_key,
        c.machine_id,
        c.event_ts,
        c.event_date,
        c.temperature_c,
        c.vibration_mm_s,
        c.pressure_kpa,
        c.rpm,
        c.current_a,
        c.firmware_version,
        c._processed_at
    FROM cleaned c   
    LEFT JOIN {{ ref('dim_machines') }} m
        on c.machine_id = m.machine_id
)

SELECT * FROM final 