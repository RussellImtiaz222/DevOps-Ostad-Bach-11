"""
Main Flask application for the CI/CD Pipeline Demo.
Demonstrates best practices for testing, security, and performance.
"""

from flask import Flask, jsonify, request
import os
import logging
from datetime import datetime
from typing import Tuple, Dict

# Initialize Flask app
app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load configuration from environment variables
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///app.db')
API_KEY = os.getenv('API_KEY', None)  # Should be set via secrets
DEBUG_MODE = os.getenv('DEBUG_MODE', 'False').lower() == 'true'


class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


def validate_email(email: str) -> bool:
    """
    Validate email format.
    
    Args:
        email: Email string to validate
        
    Returns:
        bool: True if valid, False otherwise
    """
    if not email or '@' not in email:
        return False
    parts = email.split('@')
    return len(parts) == 2 and len(parts[0]) > 0 and len(parts[1]) > 0


def calculate_discount(amount: float, quantity: int) -> float:
    """
    Calculate discount based on quantity.
    
    Args:
        amount: Base amount
        quantity: Number of items
        
    Returns:
        float: Discounted amount
    """
    if amount <= 0 or quantity <= 0:
        raise ValidationError("Amount and quantity must be positive")
    
    if quantity >= 10:
        return amount * 0.9  # 10% discount
    elif quantity >= 5:
        return amount * 0.95  # 5% discount
    return amount


def authenticate_request(req) -> bool:
    """
    Authenticate incoming request.
    
    Args:
        req: Flask request object
        
    Returns:
        bool: True if authenticated
    """
    auth_header = req.headers.get('Authorization')
    if not auth_header:
        return False
    
    if not auth_header.startswith('Bearer '):
        return False
    
    token = auth_header[7:]  # Remove 'Bearer ' prefix
    return token == API_KEY if API_KEY else True


@app.route('/health', methods=['GET'])
def health_check() -> Tuple[Dict, int]:
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    }), 200


@app.route('/api/user', methods=['POST'])
def create_user() -> Tuple[Dict, int]:
    """
    Create a new user.
    
    Returns:
        Response with user data or error
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        email = data.get('email', '').strip()
        name = data.get('name', '').strip()
        
        if not email or not name:
            return jsonify({'error': 'Email and name are required'}), 400
        
        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400
        
        if len(name) < 2:
            return jsonify({'error': 'Name must be at least 2 characters'}), 400
        
        logger.info(f"User created: {email}")
        
        return jsonify({
            'id': 1,
            'email': email,
            'name': name,
            'created_at': datetime.utcnow().isoformat()
        }), 201
        
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/order', methods=['POST'])
def create_order() -> Tuple[Dict, int]:
    """
    Create a new order with discount calculation.
    
    Returns:
        Response with order data or error
    """
    try:
        if not authenticate_request(request):
            return jsonify({'error': 'Unauthorized'}), 401
        
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        amount = data.get('amount')
        quantity = data.get('quantity')
        
        if amount is None or quantity is None:
            return jsonify({'error': 'Amount and quantity are required'}), 400
        
        try:
            amount = float(amount)
            quantity = int(quantity)
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid amount or quantity'}), 400
        
        discounted_amount = calculate_discount(amount, quantity)
        
        logger.info(f"Order created: amount={amount}, quantity={quantity}")
        
        return jsonify({
            'order_id': 1,
            'original_amount': amount,
            'quantity': quantity,
            'discounted_amount': discounted_amount,
            'discount_percentage': ((amount - discounted_amount) / amount * 100) if amount > 0 else 0
        }), 201
        
    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        logger.error(f"Error creating order: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/search', methods=['GET'])
def search() -> Tuple[Dict, int]:
    """
    Search endpoint with query parameter.
    
    Returns:
        Response with search results
    """
    try:
        query = request.args.get('q', '').strip()
        
        if not query:
            return jsonify({'error': 'Query parameter is required'}), 400
        
        if len(query) < 2:
            return jsonify({'error': 'Query must be at least 2 characters'}), 400
        
        # Simulate search results
        results = [
            {'id': 1, 'title': f'Result for {query}'},
            {'id': 2, 'title': f'Another result for {query}'}
        ]
        
        logger.info(f"Search executed: {query}")
        
        return jsonify({
            'query': query,
            'count': len(results),
            'results': results
        }), 200
        
    except Exception as e:
        logger.error(f"Error searching: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


@app.errorhandler(404)
def not_found(error) -> Tuple[Dict, int]:
    """Handle 404 errors."""
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error) -> Tuple[Dict, int]:
    """Handle 500 errors."""
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    # Note: Should not use debug=True in production
    app.run(host='0.0.0.0', port=5000, debug=DEBUG_MODE)
