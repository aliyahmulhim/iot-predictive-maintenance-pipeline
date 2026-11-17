# Industrial IoT Predictive Maintenance Data Pipeline

An end-to-end, production-style Data Engineering pipeline designed to ingest high-frequency industrial sensor telemetry, enforce schema and data quality rules, model a Kimball Star Schema with Slowly Changing Dimensions (SCD Type 2), and surface early equipment degradation signals for reliability engineers.

---
```text
## Architecture & Data Flow

[Python IIoT Simulator] ---> [Azure ADLS Gen2 (Bronze)] ---> [Snowflake (RAW / SILVER)] ---> [dbt Core (GOLD Star Schema)] ---> [Snowsight Dashboard]
         |                                                                                               ^
         +------------------------------- Orchestrated by Apache Airflow --------------------------------+
```
---

## Tech Stack
• Data Generation: Python (Synthetic telemetry with injected nulls, sensor glitches, duplicate deliveries, schema drift, and gradual 72-hour pre-failure degradation).

• Cloud Storage & Warehouse: Azure Data Lake Storage Gen2 (Bronze landing) & Snowflake (RAW, SILVER, SNAPSHOTS, GOLD schemas).

• Transformation & Modeling: dbt Core (dbt-snowflake, dbt_utils) implementing incremental models, SCD Type 2 snapshots, and 40 automated data quality tests.

• Orchestration: Apache Airflow (Dockerized DAG managing task dependencies, retries, and documentation generation).

• Visualization: Snowflake Snowsight Dashboards

---
```text
iot-predictive-maintenance/
├── airflow/
│   └── dags/
│       └── iot_pm_dag.py                 # Airflow orchestration DAG
├── docs/                                 # Architecture & execution screenshots
├── ingestion/
│   └── upload_to_adls.py                 # Azure ADLS Gen2 Bronze ingestion script
├── iot_pm/                               # dbt Core project
│   ├── models/
│   │   ├── staging/                      # Silver layer views & source definitions
│   │   └── marts/                        # Gold Kimball Star Schema facts & dimensions
│   └── snapshots/                        # SCD Type 2 machine history snapshot
├── simulator/                            # Synthetic IIoT telemetry generator
├── snowflake/                            # Ordered SQL setup, seeding & analytics scripts
│   ├── 01_setup_infrastructure.sql
│   ├── 02_seed_reference_and_maintenance.sql
│   ├── 03_scd2_simulation_and_verification.sql
│   └── 04_analytics_and_dashboard_queries.sql
└── docker-compose.yml                    # Local Airflow standalone container setup
```
---

## Dimensional Model (Kimball Star Schema)
• dim_machines & snap_machines (SCD Type 2): Tracks historical changes in machine plant assignments (plant_id) and criticality using dbt snapshot (dbt_valid_from, dbt_valid_to).

• dim_date: Conformed calendar dimension generated via dbt_utils.date_spine.

• fct_sensor_readings & fct_sensor_readings_hourly: Granular and hourly aggregated telemetry (temperature, vibration, pressure, RPM, current).

• fct_machine_health_daily: Rolling 7-day averages, 30-day isolated baselines, Z-score anomaly metrics, and health_risk_level (LOW, MEDIUM, HIGH).

• fct_maintenance_events: Tracks preventive and failure maintenance events, downtime hours, and repair costs.

---

## Key Engineering Decisions & Challenges Solved
1- Preventing Baseline Contamination in Rolling Windows:

  • Problem: Including the most recent 7 days inside the 30-day baseline window diluted Z-scores during gradual equipment degradation.
  
  • Solution: Isolated the historical baseline window (ROWS BETWEEN 36 PRECEDING AND 7 PRECEDING) so current drift is measured strictly against healthy historical     behavior.

2- Stabilizing Z-Score Explosions:

  • Problem: Near-zero standard deviation during periods of steady operation caused extreme Z-score spikes (> 2600).
  
  • Solution: Applied a minimum standard deviation floor (std_floor) and validated bounds with dbt_utils.accepted_range tests.

3- Cloud Storage Continuity:

  • Implementation: Built and tested initial Bronze ingestion against Azure ADLS Gen2 (ingestion/upload_to_adls.py). After trial subscription expiration,     seamlessly transitioned reference data seeding directly into Snowflake RAW tables without disrupting downstream dbt transformations.

4- SCD Type 2 Asset Tracking:

  • Implementation: Configured snap_machines with strategy='check' on plant_id, machine_type, and criticality to preserve full historical auditability when assets     relocate across plants

---

## Pipeline Proof & Visuals
1. Snowsight Fleet Health & Vibration Drift Dashboard
2. Apache Airflow Orchestration DAG
3. dbt Data Lineage & Quality Tests (40/40 Passing)
4. SCD Type 2 Historical Tracking (snap_machines

---

## Future Work
• Add a Python/Snowpark gradient-boosted classification model to predict Remaining Useful Life (RUL).

• Implement CI/CD linting and automated dbt build checks via GitHub Actions on pull requests.

• Connect Slack webhooks for real-time HIGH risk alerts
