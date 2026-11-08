-- Industrial OT Analytics Engine - Database Schema Definition
-- Reference Model: FAC_GLOBAL_01 (100% Anonymized Synthetic Data)

CREATE TYPE asset_status_enum AS ENUM ('RUNNING', 'UNPLANNED_STOP', 'PLANNED_MAINTENANCE', 'DEGRADED');

-- Table 1: Equipment Master Data
CREATE TABLE IF NOT EXISTS equipment_master (
    asset_id VARCHAR(50) PRIMARY KEY,       -- e.g., 'FAC_GLOBAL_01_PACK_01'
    asset_name VARCHAR(100) NOT NULL,
    line_code VARCHAR(50) NOT NULL,         -- e.g., 'LINE_ALPHA'
    design_speed_ppm INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: Downtime & Technical Debt Logs
CREATE TABLE IF NOT EXISTS downtime_logs (
    event_id SERIAL PRIMARY KEY,
    asset_id VARCHAR(50) REFERENCES equipment_master(asset_id),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INT GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (end_time - start_time))::INT) STORED,
    stop_reason_category VARCHAR(100),       -- e.g., 'ELECTRICAL_SENSOR_FAILURE'
    technical_debt_impact_score NUMERIC(5, 2), -- MOP V7 Score (0.00 to 100.00)
    status asset_status_enum DEFAULT 'UNPLANNED_STOP'
);

CREATE INDEX IF NOT EXISTS idx_downtime_asset_time ON downtime_logs (asset_id, start_time DESC);

-- Materialized View: Monthly Asset Performance KPIs
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_asset_kpis AS
SELECT 
    asset_id,
    DATE_TRUNC('month', start_time) AS calculation_month,
    COUNT(event_id) AS total_unplanned_stops,
    ROUND(SUM(duration_seconds) / 3600.0, 2) AS total_downtime_hours,
    ROUND(AVG(duration_seconds) / 60.0, 2) AS mttr_minutes,
    ROUND(AVG(technical_debt_impact_score), 2) AS avg_mop_v7_tech_debt
FROM downtime_logs
WHERE status = 'UNPLANNED_STOP' AND end_time IS NOT NULL
GROUP BY asset_id, DATE_TRUNC('month', start_time);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_asset_month ON mv_monthly_asset_kpis (asset_id, calculation_month);
