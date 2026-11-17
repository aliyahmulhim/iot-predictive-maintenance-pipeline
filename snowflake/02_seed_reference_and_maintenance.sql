USE DATABASE IOT_PM;
USE SCHEMA RAW;

-- 1. Populate Machine Master Metadata
CREATE OR REPLACE TABLE IOT_PM.RAW.MACHINES AS
SELECT DISTINCT
    machine_id,
    CASE
        WHEN MOD(CAST(SUBSTR(machine_id, 2) AS INT), 3) = 0 THEN 'PUMP'
        WHEN MOD(CAST(SUBSTR(machine_id, 2) AS INT), 3) = 1 THEN 'COMPRESSOR'
        ELSE 'MOTOR'
    END AS machine_type,
    CASE
        WHEN CAST(SUBSTR(machine_id, 2) AS INT) < 7 THEN 'PLANT_A'
        WHEN CAST(SUBSTR(machine_id, 2) AS INT) < 14 THEN 'PLANT_B'
        ELSE 'PLANT_C'
    END AS plant_id,
    CASE
        WHEN MOD(CAST(SUBSTR(machine_id, 2) AS INT), 2) = 0 THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS criticality,
    DATEADD('day', -500, CURRENT_DATE()) AS install_date,
    CURRENT_TIMESTAMP() AS _loaded_at
FROM IOT_PM.RAW.SENSOR_READINGS;

-- 2. Populate Preventive & Failure Maintenance Events
CREATE OR REPLACE TABLE IOT_PM.RAW.MAINTENANCE_LOGS AS
WITH base_machines AS (
    SELECT DISTINCT machine_id FROM IOT_PM.RAW.SENSOR_READINGS
),
preventive AS (
    SELECT
        UUID_STRING() AS event_id,
        machine_id,
        DATEADD('hour', ABS(MOD(HASH(machine_id), 240)), '2026-01-05 08:00:00'::TIMESTAMP_NTZ) AS event_ts,
        'PREVENTIVE' AS event_type,
        ROUND(UNIFORM(1.5, 4.0, RANDOM()), 1) AS downtime_hours,
        ROUND(UNIFORM(300, 900, RANDOM()), 2) AS cost_usd,
        CURRENT_TIMESTAMP() AS _loaded_at
    FROM base_machines
),
failures AS (
    SELECT
        UUID_STRING() AS event_id,
        machine_id,
        MAX(event_ts) AS event_ts,
        'FAILURE' AS event_type,
        ROUND(UNIFORM(6.0, 18.0, RANDOM()), 1) AS downtime_hours,
        ROUND(UNIFORM(2500, 7500, RANDOM()), 2) AS cost_usd,
        CURRENT_TIMESTAMP() AS _loaded_at
    FROM IOT_PM.RAW.SENSOR_READINGS
    WHERE vibration_mm_s > 2.5 OR temperature_c > 85
    GROUP BY machine_id
)
SELECT * FROM preventive
UNION ALL
SELECT * FROM failures;