USE ROLE ACCOUNTADMIN;

-- 1. Create Compute Warehouse (Auto-suspend enabled for cost optimization)
CREATE WAREHOUSE IF NOT EXISTS WH_IOT
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 2. Create Database and Medallion Architecture Schemas
CREATE DATABASE IF NOT EXISTS IOT_PM;

CREATE SCHEMA IF NOT EXISTS IOT_PM.RAW;
CREATE SCHEMA IF NOT EXISTS IOT_PM.SILVER;
CREATE SCHEMA IF NOT EXISTS IOT_PM.GOLD;
CREATE SCHEMA IF NOT EXISTS IOT_PM.SNAPSHOTS;

USE DATABASE IOT_PM;
USE SCHEMA RAW;

-- 3. Create Raw Landing Tables
CREATE TABLE IF NOT EXISTS IOT_PM.RAW.MACHINES (
    machine_id STRING,
    machine_type STRING,
    plant_id STRING,
    criticality STRING,
    install_date DATE,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS IOT_PM.RAW.MAINTENANCE_LOGS (
    event_id STRING,
    machine_id STRING,
    event_ts TIMESTAMP_NTZ,
    event_type STRING,
    downtime_hours FLOAT,
    cost_usd FLOAT,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS IOT_PM.RAW.SENSOR_READINGS (
    event_id STRING,
    machine_id STRING,
    event_ts TIMESTAMP_NTZ,
    temperature_c FLOAT,
    vibration_mm_s FLOAT,
    pressure_kpa FLOAT,
    rpm FLOAT,
    current_a FLOAT,
    firmware_version STRING,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4. Configure File Format & External Azure ADLS Gen2 Stage
CREATE OR REPLACE FILE FORMAT IOT_PM.RAW.JSON_FORMAT
    TYPE = JSON
    STRIP_OUTER_ARRAY = FALSE;

CREATE OR REPLACE STAGE IOT_PM.RAW.AZURE_IOT_STAGE
    URL = 'azure://iotpmproject.blob.core.windows.net/bronze/iot_sensor/'
    CREDENTIALS = (AZURE_SAS_TOKEN = '<AZURE_SAS_TOKEN>')
    FILE_FORMAT = IOT_PM.RAW.JSON_FORMAT;

-- 5. Bulk Ingest Raw Sensor Telemetry from Bronze Stage
COPY INTO IOT_PM.RAW.SENSOR_READINGS (
    event_id, machine_id, event_ts, temperature_c, vibration_mm_s,
    pressure_kpa, rpm, current_a, firmware_version
)
FROM (
    SELECT
        $1:event_id::STRING,
        $1:machine_id::STRING,
        $1:event_ts::TIMESTAMP_NTZ,
        $1:temperature_c::FLOAT,
        $1:vibration_mm_s::FLOAT,
        $1:pressure_kpa::FLOAT,
        $1:rpm::FLOAT,
        $1:current_a::FLOAT,
        $1:firmware_version::STRING
    FROM @IOT_PM.RAW.AZURE_IOT_STAGE
)
FILE_FORMAT = (TYPE = JSON)
PATTERN = '.*dt=2026-01-.*'
ON_ERROR = 'CONTINUE';