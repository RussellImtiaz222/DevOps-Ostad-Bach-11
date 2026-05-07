-- Migration 002: Add measurement date enhancements
-- This migration adds additional constraints and triggers for data integrity

-- Add constraint to ensure valid BMI values
ALTER TABLE measurements
ADD CONSTRAINT chk_height_positive CHECK (height > 0),
ADD CONSTRAINT chk_weight_positive CHECK (weight > 0),
ADD CONSTRAINT chk_measurement_date_not_future CHECK (measurement_date <= CURRENT_DATE);

-- Create trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_measurement_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

DROP TRIGGER IF EXISTS measurements_audit_log ON measurements;
CREATE TRIGGER measurements_audit_log
    AFTER INSERT OR UPDATE OR DELETE ON measurements
    FOR EACH ROW
    EXECUTE FUNCTION log_measurement_changes();
