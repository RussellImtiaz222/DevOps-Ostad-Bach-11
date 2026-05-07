-- BMI Health Tracker Database Initialization
-- PostgreSQL 14+ initialization script

-- Create database
CREATE DATABASE bmidb;

-- Connect to the database
\c bmidb;

-- Create schema and user
CREATE SCHEMA IF NOT EXISTS public;

-- Create measurements table for BMI Health Tracker
CREATE TABLE IF NOT EXISTS measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    height DECIMAL(5, 2) NOT NULL,
    weight DECIMAL(6, 2) NOT NULL,
    bmi DECIMAL(5, 2),
    measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for common queries
CREATE INDEX idx_measurements_date ON measurements(measurement_date DESC);
CREATE INDEX idx_measurements_created ON measurements(created_at DESC);
CREATE INDEX idx_measurements_bmi ON measurements(bmi);

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

CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

-- Insert sample measurements data
INSERT INTO measurements (id, height, weight, bmi, measurement_date, notes) VALUES
    (gen_random_uuid(), 1.75, 80.5, 26.20, CURRENT_DATE - INTERVAL '7 days', 'Initial measurement'),
    (gen_random_uuid(), 1.75, 80.0, 26.12, CURRENT_DATE - INTERVAL '6 days', 'Weekly check'),
    (gen_random_uuid(), 1.75, 79.5, 26.04, CURRENT_DATE - INTERVAL '5 days', 'Weekly check'),
    (gen_random_uuid(), 1.75, 79.0, 25.96, CURRENT_DATE - INTERVAL '4 days', 'Weekly check'),
    (gen_random_uuid(), 1.75, 78.5, 25.88, CURRENT_DATE, 'Latest measurement');

-- Create trigger function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_measurement_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at
DROP TRIGGER IF EXISTS measurements_update_timestamp ON measurements;
CREATE TRIGGER measurements_update_timestamp
    BEFORE UPDATE ON measurements
    FOR EACH ROW
    EXECUTE FUNCTION update_measurement_timestamp();

-- Create trigger for audit logging
CREATE OR REPLACE FUNCTION log_measurement_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (action, table_name, record_id, old_values, new_values)
    VALUES (
        TG_OP,
        'measurements',
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger for audit logging
DROP TRIGGER IF EXISTS measurements_audit_log ON measurements;
CREATE TRIGGER measurements_audit_log
    AFTER INSERT OR UPDATE OR DELETE ON measurements
    FOR EACH ROW
    EXECUTE FUNCTION log_measurement_changes();

-- Create view for measurement statistics
CREATE OR REPLACE VIEW measurement_statistics AS
SELECT
    COUNT(*) as total_measurements,
    ROUND(AVG(bmi)::numeric, 2) as avg_bmi,
    ROUND(MIN(bmi)::numeric, 2) as min_bmi,
    ROUND(MAX(bmi)::numeric, 2) as max_bmi,
    ROUND(AVG(weight)::numeric, 2) as avg_weight,
    COUNT(CASE WHEN measurement_date > CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as measurements_this_week
FROM measurements;

-- Grant permissions to bmi_user (replace with actual user after creation)
GRANT CONNECT ON DATABASE bmidb TO postgres;
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
