-- PostgreSQL Database Schema
-- 3-Tier Application Database

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_last_name ON users(last_name);

-- Create application logs table
CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    level VARCHAR(20) NOT NULL,
    logger VARCHAR(255),
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    request_id VARCHAR(255),
    user_id INT REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes for logs table
CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);

-- Create application metrics table
CREATE TABLE IF NOT EXISTS app_metrics (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(255) NOT NULL,
    metric_value DECIMAL(10, 2),
    unit VARCHAR(50),
    tags JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for metrics table
CREATE INDEX IF NOT EXISTS idx_metrics_name ON app_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON app_metrics(timestamp);

-- Create user activities table
CREATE TABLE IF NOT EXISTS user_activities (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for user_activities table
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_timestamp ON user_activities(timestamp);
CREATE INDEX IF NOT EXISTS idx_activities_type ON user_activities(activity_type);

-- Insert sample data
INSERT INTO users (first_name, last_name, email, city, country) VALUES
    ('John', 'Doe', 'john.doe@example.com', 'New York', 'USA'),
    ('Jane', 'Smith', 'jane.smith@example.com', 'San Francisco', 'USA'),
    ('Bob', 'Johnson', 'bob.johnson@example.com', 'Chicago', 'USA')
ON CONFLICT (email) DO NOTHING;

-- Create view for active users
CREATE OR REPLACE VIEW active_users AS
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    COUNT(ua.id) as activity_count,
    MAX(ua.timestamp) as last_activity
FROM users u
LEFT JOIN user_activities ua ON u.id = ua.user_id
GROUP BY u.id, u.first_name, u.last_name, u.email;

-- Create stored procedures/functions for common operations
CREATE OR REPLACE FUNCTION get_user_count()
RETURNS TABLE(user_count BIGINT) AS $$
BEGIN
    RETURN QUERY SELECT COUNT(*) FROM users;
END;
$$ LANGUAGE plpgsql;

-- Function to get recent logs
CREATE OR REPLACE FUNCTION get_recent_logs(limit_count INT DEFAULT 10)
RETURNS TABLE(id INT, level VARCHAR, message TEXT, log_timestamp TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT logs.id, logs.level, logs.message, logs.timestamp 
    FROM logs 
    ORDER BY logs.timestamp DESC 
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
