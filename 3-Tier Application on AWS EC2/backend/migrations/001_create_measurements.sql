-- Migration 001: Create measurements table for BMI Health Tracker
-- This migration creates the core measurements table for storing BMI data

CREATE TABLE IF NOT EXISTS measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    height DECIMAL(5, 2) NOT NULL COMMENT 'Height in meters',
    weight DECIMAL(6, 2) NOT NULL COMMENT 'Weight in kilograms',
    bmi DECIMAL(5, 2) GENERATED ALWAYS AS (ROUND((weight / (height * height))::numeric, 2)) STORED,
    measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_measurements_date ON measurements(measurement_date DESC);
CREATE INDEX IF NOT EXISTS idx_measurements_created ON measurements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_measurements_bmi ON measurements(bmi);

-- Create audit log table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
