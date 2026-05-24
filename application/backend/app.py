#!/usr/bin/env python3
"""
3-Tier Application - Backend API
Flask application for managing users and interfacing with RDS database
"""

import os
import json
import logging
from datetime import datetime
from functools import wraps

from flask import Flask, request, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import psycopg2
from psycopg2.extras import DictCursor
from psycopg2 import Error

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Prometheus metrics
request_count = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])

# Database configuration from environment variables
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'password'),
    'database': os.getenv('DB_NAME', 'appdb'),
    'port': int(os.getenv('DB_PORT', 5432)),
}

AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# Application start time for uptime calculation
start_time = datetime.now()


def get_db_connection():
    """Create a database connection"""
    try:
        connection = psycopg2.connect(**DB_CONFIG)
        logger.info(f"Connected to PostgreSQL database: {DB_CONFIG['database']} on {DB_CONFIG['host']}")
        return connection
    except Error as e:
        logger.error(f"Database connection error: {str(e)}")
        raise


def track_metrics(f):
    """Decorator to track request metrics"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        endpoint = request.endpoint or 'unknown'
        method = request.method
        
        try:
            with request_duration.labels(method=method, endpoint=endpoint).time():
                response = f(*args, **kwargs)
                status = response[1] if isinstance(response, tuple) else 200
                request_count.labels(method=method, endpoint=endpoint, status=status).inc()
                return response
        except Exception as e:
            request_count.labels(method=method, endpoint=endpoint, status='500').inc()
            raise
    
    return decorated_function


@app.route('/health', methods=['GET'])
@track_metrics
def health_check():
    """Health check endpoint"""
    uptime = (datetime.now() - start_time).total_seconds()
    return jsonify({
        'status': 'healthy',
        'uptime': int(uptime),
        'timestamp': datetime.now().isoformat(),
        'service': 'backend-api'
    }), 200


@app.route('/system-info', methods=['GET'])
@track_metrics
def system_info():
    """Get system information"""
    return jsonify({
        'server_version': '1.0.0',
        'database': 'PostgreSQL',
        'database_name': DB_CONFIG['database'],
        'host': DB_CONFIG['host'],
        'region': AWS_REGION,
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'timestamp': datetime.now().isoformat()
    }), 200


@app.route('/db-status', methods=['GET'])
@track_metrics
def db_status():
    """Check database connectivity"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_database()")
            result = cursor.fetchone()
            connection.close()
        
        return jsonify({
            'status': 'connected',
            'connection': 'successful',
            'database': result[0],
            'engine': 'PostgreSQL',
            'timestamp': datetime.now().isoformat()
        }), 200
    except Exception as e:
        logger.error(f"Database status check failed: {str(e)}")
        return jsonify({
            'status': 'disconnected',
            'connection': 'failed',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 503


@app.route('/users', methods=['POST'])
@track_metrics
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        
        # Validate input
        if not data or not all(k in data for k in ['first_name', 'last_name', 'email']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        first_name = data.get('first_name', '').strip()
        last_name = data.get('last_name', '').strip()
        email = data.get('email', '').strip()
        
        if not (first_name and last_name and email):
            return jsonify({'error': 'Fields cannot be empty'}), 400
        
        # Insert into database
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                sql = """
                    INSERT INTO users (first_name, last_name, email, created_at)
                    VALUES (%s, %s, %s, NOW())
                    RETURNING id, first_name, last_name, email, created_at
                """
                cursor.execute(sql, (first_name, last_name, email))
                user = cursor.fetchone()
                connection.commit()
            
            logger.info(f"User created: {user[0]} - {email}")
            return jsonify({
                'user_id': user[0],
                'first_name': user[1],
                'last_name': user[2],
                'email': user[3],
                'created_at': user[4].isoformat() if user[4] else None,
                'message': 'User created successfully'
            }), 201
        finally:
            connection.close()
    
    except Error as e:
        logger.error(f"Database error: {str(e)}")
        return jsonify({'error': f'Database error: {str(e)}'}), 500
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users', methods=['GET'])
@track_metrics
def get_users():
    """Get all users"""
    try:
        connection = get_db_connection()
        try:
            with connection.cursor(cursor_factory=DictCursor) as cursor:
                sql = "SELECT id, first_name, last_name, email, created_at FROM users ORDER BY created_at DESC"
                cursor.execute(sql)
                users = cursor.fetchall()
            
            logger.info(f"Retrieved {len(users)} users")
            return jsonify({
                'users': [dict(user) for user in users],
                'count': len(users),
                'timestamp': datetime.now().isoformat()
            }), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error retrieving users: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users/<int:user_id>', methods=['GET'])
@track_metrics
def get_user(user_id):
    """Get a specific user"""
    try:
        connection = get_db_connection()
        try:
            with connection.cursor(cursor_factory=DictCursor) as cursor:
                sql = "SELECT id, first_name, last_name, email, created_at FROM users WHERE id = %s"
                cursor.execute(sql, (user_id,))
                user = cursor.fetchone()
            
            if not user:
                return jsonify({'error': 'User not found'}), 404
            
            return jsonify({
                'user': dict(user),
                'timestamp': datetime.now().isoformat()
            }), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error retrieving user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users/<int:user_id>', methods=['PUT'])
@track_metrics
def update_user(user_id):
    """Update a user"""
    try:
        data = request.get_json()
        
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                # Check if user exists
                sql = "SELECT id FROM users WHERE id = %s"
                cursor.execute(sql, (user_id,))
                if not cursor.fetchone():
                    return jsonify({'error': 'User not found'}), 404
                
                # Update user
                updates = []
                params = []
                for key in ['first_name', 'last_name', 'email']:
                    if key in data:
                        updates.append(f"{key} = %s")
                        params.append(data[key])
                
                if not updates:
                    return jsonify({'error': 'No fields to update'}), 400
                
                params.append(user_id)
                sql = f"UPDATE users SET {', '.join(updates)} WHERE id = %s"
                cursor.execute(sql, params)
                connection.commit()
            
            logger.info(f"User updated: {user_id}")
            return jsonify({'message': 'User updated successfully'}), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error updating user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users/<int:user_id>', methods=['DELETE'])
@track_metrics
def delete_user(user_id):
    """Delete a user"""
    try:
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                sql = "DELETE FROM users WHERE id = %s"
                cursor.execute(sql, (user_id,))
                connection.commit()
                
                if cursor.rowcount == 0:
                    return jsonify({'error': 'User not found'}), 404
            
            logger.info(f"User deleted: {user_id}")
            return jsonify({'message': 'User deleted successfully'}), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error deleting user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    logger.info("Starting Backend API")
    logger.info(f"Database Host: {DB_CONFIG['host']}")
    logger.info(f"Database Name: {DB_CONFIG['database']}")
    logger.info(f"Database Engine: PostgreSQL")
    logger.info(f"AWS Region: {AWS_REGION}")
    
    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=8080,
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )


AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# Application start time for uptime calculation
start_time = datetime.now()


def get_db_connection():
    """Create a database connection"""
    try:
        connection = psycopg2.connect(**DB_CONFIG)
        logger.info(f"Connected to PostgreSQL database: {DB_CONFIG['database']} on {DB_CONFIG['host']}")
        return connection
    except Error as e:
        logger.error(f"Database connection error: {str(e)}")
        raise


def track_metrics(f):
    """Decorator to track request metrics"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        endpoint = request.endpoint or 'unknown'
        method = request.method
        
        try:
            with request_duration.labels(method=method, endpoint=endpoint).time():
                response = f(*args, **kwargs)
                status = response[1] if isinstance(response, tuple) else 200
                request_count.labels(method=method, endpoint=endpoint, status=status).inc()
                return response
        except Exception as e:
            request_count.labels(method=method, endpoint=endpoint, status='500').inc()
            raise
    
    return decorated_function


@app.route('/health', methods=['GET'])
@track_metrics
def health_check():
    """Health check endpoint"""
    uptime = (datetime.now() - start_time).total_seconds()
    return jsonify({
        'status': 'healthy',
        'uptime': int(uptime),
        'timestamp': datetime.now().isoformat(),
        'service': 'backend-api'
    }), 200


@app.route('/system-info', methods=['GET'])
@track_metrics
def system_info():
    """Get system information"""
    return jsonify({
        'server_version': '1.0.0',
        'database': DB_CONFIG['database'],
        'host': DB_CONFIG['host'],
        'region': AWS_REGION,
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'timestamp': datetime.now().isoformat()
    }), 200


@app.route('/db-status', methods=['GET'])
@track_metrics
def db_status():
    """Check database connectivity"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT DATABASE()")
            result = cursor.fetchone()
            connection.close()
        
        return jsonify({
            'status': 'connected',
            'connection': 'successful',
            'database': result[list(result.keys())[0]],
            'timestamp': datetime.now().isoformat()
        }), 200
    except Exception as e:
        logger.error(f"Database status check failed: {str(e)}")
        return jsonify({
            'status': 'disconnected',
            'connection': 'failed',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 503


@app.route('/users', methods=['POST'])
@track_metrics
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        
        # Validate input
        if not data or not all(k in data for k in ['first_name', 'last_name', 'email']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        first_name = data.get('first_name', '').strip()
        last_name = data.get('last_name', '').strip()
        email = data.get('email', '').strip()
        
        if not (first_name and last_name and email):
            return jsonify({'error': 'Fields cannot be empty'}), 400
        
        # Insert into database
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                sql = """
                    INSERT INTO users (first_name, last_name, email, created_at)
                    VALUES (%s, %s, %s, NOW())
                """
                cursor.execute(sql, (first_name, last_name, email))
                connection.commit()
                user_id = cursor.lastrowid
            
            logger.info(f"User created: {user_id} - {email}")
            return jsonify({
                'user_id': user_id,
                'first_name': first_name,
                'last_name': last_name,
                'email': email,
                'message': 'User created successfully'
            }), 201
        finally:
            connection.close()
    
    except Error as e:
        logger.error(f"Database error: {str(e)}")
        return jsonify({'error': f'Database error: {str(e)}'}), 500
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users', methods=['GET'])
@track_metrics
def get_users():
    """Get all users"""
    try:
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                sql = "SELECT id, first_name, last_name, email, created_at FROM users ORDER BY created_at DESC"
                cursor.execute(sql)
                users = cursor.fetchall()
            
            logger.info(f"Retrieved {len(users)} users")
            return jsonify({
                'users': users,
                'count': len(users),
                'timestamp': datetime.now().isoformat()
            }), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error retrieving users: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users/<int:user_id>', methods=['GET'])
@track_metrics
def get_user(user_id):
    """Get a specific user"""
    try:
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                sql = "SELECT id, first_name, last_name, email, created_at FROM users WHERE id = %s"
                cursor.execute(sql, (user_id,))
                user = cursor.fetchone()
            
            if not user:
                return jsonify({'error': 'User not found'}), 404
            
            return jsonify({
                'user': user,
                'timestamp': datetime.now().isoformat()
            }), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error retrieving user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users/<int:user_id>', methods=['PUT'])
@track_metrics
def update_user(user_id):
    """Update a user"""
    try:
        data = request.get_json()
        
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                # Check if user exists
                sql = "SELECT id FROM users WHERE id = %s"
                cursor.execute(sql, (user_id,))
                if not cursor.fetchone():
                    return jsonify({'error': 'User not found'}), 404
                
                # Update user
                updates = []
                params = []
                for key in ['first_name', 'last_name', 'email']:
                    if key in data:
                        updates.append(f"{key} = %s")
                        params.append(data[key])
                
                if not updates:
                    return jsonify({'error': 'No fields to update'}), 400
                
                params.append(user_id)
                sql = f"UPDATE users SET {', '.join(updates)} WHERE id = %s"
                cursor.execute(sql, params)
                connection.commit()
            
            logger.info(f"User updated: {user_id}")
            return jsonify({'message': 'User updated successfully'}), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error updating user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/users/<int:user_id>', methods=['DELETE'])
@track_metrics
def delete_user(user_id):
    """Delete a user"""
    try:
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                sql = "DELETE FROM users WHERE id = %s"
                cursor.execute(sql, (user_id,))
                connection.commit()
                
                if cursor.rowcount == 0:
                    return jsonify({'error': 'User not found'}), 404
            
            logger.info(f"User deleted: {user_id}")
            return jsonify({'message': 'User deleted successfully'}), 200
        finally:
            connection.close()
    
    except Exception as e:
        logger.error(f"Error deleting user: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    logger.info("Starting Backend API")
    logger.info(f"Database Host: {DB_CONFIG['host']}")
    logger.info(f"Database Name: {DB_CONFIG['database']}")
    logger.info(f"AWS Region: {AWS_REGION}")
    
    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=8080,
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )
