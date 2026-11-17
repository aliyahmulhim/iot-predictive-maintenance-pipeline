-- Simulate equipment relocation and criticality downgrade to test SCD Type 2 tracking
UPDATE IOT_PM.RAW.MACHINES
SET
    plant_id = 'PLANT_Z',
    criticality = 'LOW'
WHERE machine_id IN ('M0000', 'M0001', 'M0002');

-- Run `dbt snapshot` via CLI, then verify historical versioning:
SELECT
    machine_id,
    plant_id,
    criticality,
    dbt_valid_from,
    dbt_valid_to
FROM IOT_PM.SNAPSHOTS.SNAP_MACHINES
WHERE machine_id IN ('M0000', 'M0001', 'M0002')
ORDER BY machine_id, dbt_valid_from;