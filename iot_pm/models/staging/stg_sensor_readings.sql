{{ config(materialized='view') }}

with raw_data as (
    select * from {{ source('raw', 'sensor_readings') }}
)

select 
    machine_id,
    event_ts,
    cast(event_ts as date) as event_date,
    temperature_c,
    vibration_mm_s,
    pressure_kpa,
    rpm,
    current_a,
    firmware_version,
    _loaded_at as _processed_at
from raw_data   

