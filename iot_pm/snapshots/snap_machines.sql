{% snapshot snap_machines %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='machine_id',
        strategy='check',
        check_cols=['plant_id', 'machine_type', 'criticality']
    )
}}

SELECT 
    machine_id,
    machine_type,
    plant_id,
    criticality,
    install_date
FROM {{ source('raw', 'machines') }}    

{% endsnapshot %}