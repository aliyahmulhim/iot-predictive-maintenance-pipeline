SELECT
    e.event_id,
    {{ dbt_utils.generate_surrogate_key(['e.machine_id']) }} AS machine_key,
    e.event_date AS date_key,
    e.event_ts,
    e.event_type,
    e.downtime_hours,
    e.cost_usd
FROM {{ ref('stg_maintenance_events') }} e