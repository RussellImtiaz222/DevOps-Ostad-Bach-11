#!/bin/bash
"""
Database initialization script
Creates the database schema and initial tables
"""

import psycopg2
from psycopg2 import Error
import os
import sys
import logging
from time import sleep

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def wait_for_db(host, user, password, database, max_retries=30):
    """Wait for database to be ready"""
    for attempt in range(max_retries):
        try:
            connection = psycopg2.connect(
                host=host,
                user=user,
                password=password,
                database=database
            )
            logger.info("PostgreSQL Database is ready!")
            connection.close()
            return True
        except Error as e:
            logger.warning(f"Attempt {attempt + 1}/{max_retries}: {str(e)}")
            if attempt < max_retries - 1:
                sleep(2)
    
    logger.error("Database failed to become ready in time")
    return False

def initialize_database():
    """Initialize database schema"""
    db_host = os.getenv('DB_HOST', 'localhost')
    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD', 'password')
    db_name = os.getenv('DB_NAME', 'appdb')
    
    logger.info(f"Initializing PostgreSQL database: {db_name} on {db_host}")
    
    # Wait for database to be ready
    if not wait_for_db(db_host, db_user, db_password, 'postgres'):
        sys.exit(1)
    
    try:
        # Connect to PostgreSQL server
        connection = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database='postgres'
        )
        connection.autocommit = True
        
        with connection.cursor() as cursor:
            # Create database
            cursor.execute(f"CREATE DATABASE {db_name}")
            logger.info(f"Database {db_name} created or already exists")
        
        connection.close()
        
        # Connect to the new database
        connection = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        
        with connection.cursor() as cursor:
            # Create users table
            create_users_table = """
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                first_name VARCHAR(100) NOT NULL,
                last_name VARCHAR(100) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_email ON users(email);
            CREATE INDEX IF NOT EXISTS idx_created_at ON users(created_at);
            """
            
            cursor.execute(create_users_table)
            logger.info("Users table created or already exists")
            
            # Create logs table
            create_logs_table = """
            CREATE TABLE IF NOT EXISTS logs (
                id SERIAL PRIMARY KEY,
                level VARCHAR(20) NOT NULL,
                message TEXT NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_level ON logs(level);
            CREATE INDEX IF NOT EXISTS idx_timestamp ON logs(timestamp);
            """
            
            cursor.execute(create_logs_table)
            logger.info("Logs table created or already exists")
            
            # Create app_metrics table for monitoring
            create_metrics_table = """
            CREATE TABLE IF NOT EXISTS app_metrics (
                id SERIAL PRIMARY KEY,
                metric_name VARCHAR(255) NOT NULL,
                metric_value DECIMAL(10, 2) NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_metric_name ON app_metrics(metric_name);
            CREATE INDEX IF NOT EXISTS idx_timestamp_metrics ON app_metrics(timestamp);
            """
            
            cursor.execute(create_metrics_table)
            logger.info("App metrics table created or already exists")
            
            connection.commit()
            logger.info("Database initialization completed successfully")
        
        connection.close()
    
    except Error as e:
        logger.error(f"Database initialization failed: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    initialize_database()
