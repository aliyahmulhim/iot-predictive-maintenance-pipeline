SELECT 
    event_id,
    machine_id,
    event_ts,
    CAST(event_ts AS DATE) AS event_date,
    UPPER(event_type) AS event_type,
    COALESCE(downtime_hours, 0) AS downtime_hours,
    COALESCE(cost_usd, 0) AS cost_usd
FROM {{ source('raw' , 'maintenance_logs') }}    
