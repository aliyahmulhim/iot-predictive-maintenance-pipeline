-- 1. Top 10 Highest-Risk Machines on Peak Degradation Date
SELECT
    m.machine_id,
    m.machine_type,
    m.plant_id,
    h.date_key,
    ROUND(h.vib_avg, 3) AS avg_vib,
    ROUND(h.vib_baseline, 3) AS baseline_vib,
    ROUND(h.vib_zscore, 2) AS vib_zscore,
    ROUND(h.temp_zscore, 2) AS temp_zscore,
    h.health_risk_level
FROM IOT_PM.GOLD.FCT_MACHINE_HEALTH_DAILY h
JOIN IOT_PM.GOLD.DIM_MACHINES m ON m.machine_key = h.machine_key
WHERE h.date_key = '2026-01-30'
ORDER BY h.vib_zscore DESC NULLS LAST
LIMIT 10;

-- 2. Pre-Failure Vibration Drift Trajectory (Machines M0014 & M0003)
SELECT
    m.machine_id,
    h.date_key,
    ROUND(h.vib_avg, 3) AS avg_vib,
    ROUND(h.vib_baseline, 3) AS baseline,
    ROUND(h.vib_std, 5) AS std,
    ROUND(h.vib_zscore, 2) AS vib_zscore,
    h.health_risk_level
FROM IOT_PM.GOLD.FCT_MACHINE_HEALTH_DAILY h
JOIN IOT_PM.GOLD.DIM_MACHINES m ON m.machine_key = h.machine_key
WHERE m.machine_id IN ('M0014', 'M0003')
  AND h.date_key >= '2026-01-25'
ORDER BY m.machine_id, h.date_key;

-- 3. Maintenance Cost & Downtime Impact by Event Type
SELECT
    event_type,
    COUNT(*) AS total_events,
    ROUND(SUM(downtime_hours), 1) AS total_downtime_hours,
    ROUND(SUM(cost_usd), 2) AS total_cost_usd
FROM IOT_PM.GOLD.FCT_MAINTENANCE_EVENTS
GROUP BY 1;

-- 4. Pipeline Row Count & Data Quality Summary Across Medallion Layers
SELECT 'RAW.SENSOR_READINGS' AS layer_table, COUNT(*) AS row_count FROM IOT_PM.RAW.SENSOR_READINGS
UNION ALL
SELECT 'SILVER.STG_SENSOR_READINGS', COUNT(*) FROM IOT_PM.SILVER.STG_SENSOR_READINGS
UNION ALL
SELECT 'GOLD.FCT_SENSOR_READINGS', COUNT(*) FROM IOT_PM.GOLD.FCT_SENSOR_READINGS
UNION ALL
SELECT 'GOLD.FCT_SENSOR_READINGS_HOURLY', COUNT(*) FROM IOT_PM.GOLD.FCT_SENSOR_READINGS_HOURLY
UNION ALL
SELECT 'GOLD.FCT_MACHINE_HEALTH_DAILY', COUNT(*) FROM IOT_PM.GOLD.FCT_MACHINE_HEALTH_DAILY;