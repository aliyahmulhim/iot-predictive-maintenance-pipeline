{{
    config(
        materialized='table',
        schema='gold'
    )
}}


with staging_sensors as (
    select distinct 
        machine_id,
        firmware_version,
        _processed_at
    from {{ ref('stg_sensor_readings') }}
)

select 
    -- generate a unique (surrogate key) for every machine
    {{ dbt_utils.generate_surrogate_key(['machine_id']) }} as machine_key, 
    machine_id,  
    concat('Machine_', machine_id) as machine_name,
    case
        when machine_id like '%1%' then 'Production Line A'
        else 'Production Line B'
    end as production_line,
    firmware_version,
    _processed_at    
from staging_sensors    