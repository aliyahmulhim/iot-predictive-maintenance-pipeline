{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with fct_readings as (
    select * from {{ ref('fct_sensor_readings') }}
),

dim_machines as (
    select * from {{ ref('dim_machines') }}
)

select 
    m.machine_id,
    m.machine_name,
    m.production_line,
    count(f.sensor_reading_id) as total_readings, -- لمعرفة اجمالي عدد القراءات لكل اله --
    sum(case when f.is_anomaly_predicted then 1 else 0 end) as total_anomalies_detected,
    round(
        (sum(case when f.is_anomaly_predicted then 1 else 0 end) * 100.0) / nullif(count(f.sensor_reading_id), 0), -- يتحقق من انا المقام != صفر --
        2
    ) as anomaly_precentage,
    max(f.event_ts) as last_reading_timestamp

from fct_readings f
join dim_machines m on f.machine_key = m.machine_key
group by
    m.machine_id,
    m.machine_name,
    m.production_line

