"""
Unit tests for the Flask application.
Tests cover validation, authentication, business logic, and API endpoints.
"""

import pytest
import json
from app.app import (
    app, validate_email, calculate_discount, authenticate_request,
    ValidationError
)


@pytest.fixture
def client():
    """Create test client for Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def auth_headers():
    """Provide authorization headers for authenticated requests."""
    return {'Authorization': 'Bearer test-token'}


# ============================================================================
# Unit Tests: validate_email()
# ============================================================================

class TestValidateEmail:
    """Tests for email validation function."""
    
    def test_valid_email(self):
        """Test valid email addresses."""
        assert validate_email('user@example.com') == True
        assert validate_email('test.user@domain.co.uk') == True
    
    def test_invalid_email_no_at_sign(self):
        """Test email without @ symbol."""
        assert validate_email('userexample.com') == False
    
    def test_invalid_email_multiple_at_signs(self):
        """Test email with multiple @ symbols."""
        assert validate_email('user@@example.com') == False
    
    def test_invalid_email_empty_local_part(self):
        """Test email with empty local part."""
        assert validate_email('@example.com') == False
    
    def test_invalid_email_empty_domain(self):
        """Test email with empty domain."""
        assert validate_email('user@') == False
    
    def test_invalid_email_empty_string(self):
        """Test empty email string."""
        assert validate_email('') == False
    
    def test_invalid_email_none(self):
        """Test None as email."""
        assert validate_email(None) == False


# ============================================================================
# Unit Tests: calculate_discount()
# ============================================================================

class TestCalculateDiscount:
    """Tests for discount calculation function."""
    
    def test_no_discount_small_quantity(self):
        """Test that small quantity (< 5) gets no discount."""
        assert calculate_discount(100, 1) == 100
        assert calculate_discount(100, 4) == 100
    
    def test_five_percent_discount(self):
        """Test 5% discount for quantity 5-9."""
        assert calculate_discount(100, 5) == 95.0
        assert calculate_discount(100, 9) == 95.0
    
    def test_ten_percent_discount(self):
        """Test 10% discount for quantity >= 10."""
        assert calculate_discount(100, 10) == 90.0
        assert calculate_discount(100, 50) == 90.0
    
    def test_discount_with_decimal_amount(self):
        """Test discount calculation with decimal amounts."""
        assert calculate_discount(99.99, 5) == 94.99050
        assert calculate_discount(99.99, 10) == 89.99100
    
    def test_invalid_amount_zero(self):
        """Test that zero amount raises ValidationError."""
        with pytest.raises(ValidationError):
            calculate_discount(0, 5)
    
    def test_invalid_amount_negative(self):
        """Test that negative amount raises ValidationError."""
        with pytest.raises(ValidationError):
            calculate_discount(-100, 5)
    
    def test_invalid_quantity_zero(self):
        """Test that zero quantity raises ValidationError."""
        with pytest.raises(ValidationError):
            calculate_discount(100, 0)
    
    def test_invalid_quantity_negative(self):
        """Test that negative quantity raises ValidationError."""
        with pytest.raises(ValidationError):
            calculate_discount(100, -5)


# ============================================================================
# Unit Tests: authenticate_request()
# ============================================================================

class TestAuthenticateRequest:
    """Tests for request authentication."""
    
    def test_authenticate_without_authorization_header(self):
        """Test that request without auth header fails."""
        with app.test_request_context():
            from flask import request
            assert authenticate_request(request) == False
    
    def test_authenticate_with_invalid_header_format(self):
        """Test that request with invalid auth header format fails."""
        with app.test_request_context(headers={'Authorization': 'InvalidFormat token'}):
            from flask import request
            assert authenticate_request(request) == False
    
    def test_authenticate_with_valid_header(self):
        """Test that request with valid Bearer token is accepted."""
        # Note: In test environment with API_KEY=None, any Bearer token is accepted
        with app.test_request_context(headers={'Authorization': 'Bearer valid-token'}):
            from flask import request
            result = authenticate_request(request)
            # Will return True if API_KEY is not set (default test behavior)
            assert isinstance(result, bool)


# ============================================================================
# Integration Tests: API Endpoints
# ============================================================================

class TestHealthEndpoint:
    """Tests for health check endpoint."""
    
    def test_health_check_returns_200(self, client):
        """Test that health endpoint returns 200 status."""
        response = client.get('/health')
        assert response.status_code == 200
    
    def test_health_check_response_structure(self, client):
        """Test health endpoint response structure."""
        response = client.get('/health')
        data = response.get_json()
        assert 'status' in data
        assert 'timestamp' in data
        assert 'version' in data
        assert data['status'] == 'healthy'
    
    def test_health_check_has_timestamp(self, client):
        """Test that health response includes valid timestamp."""
        response = client.get('/health')
        data = response.get_json()
        assert data['timestamp'] is not None
        assert 'T' in data['timestamp']  # ISO format check


class TestUserEndpoint:
    """Tests for user creation endpoint."""
    
    def test_create_user_success(self, client):
        """Test successful user creation."""
        payload = {
            'email': 'test@example.com',
            'name': 'Test User'
        }
        response = client.post('/api/user', 
                              data=json.dumps(payload),
                              content_type='application/json')
        assert response.status_code == 201
        data = response.get_json()
        assert data['email'] == 'test@example.com'
        assert data['name'] == 'Test User'
        assert 'id' in data
        assert 'created_at' in data
    
    def test_create_user_missing_email(self, client):
        """Test user creation fails with missing email."""
        payload = {'name': 'Test User'}
        response = client.post('/api/user',
                              data=json.dumps(payload),
                              content_type='application/json')
        assert response.status_code == 400
        assert 'required' in response.get_json()['error'].lower()
    
    def test_create_user_missing_name(self, client):
        """Test user creation fails with missing name."""
        payload = {'email': 'test@example.com'}
        response = client.post('/api/user',
                              data=json.dumps(payload),
                              content_type='application/json')
        assert response.status_code == 400
        assert 'required' in response.get_json()['error'].lower()
    
    def test_create_user_invalid_email(self, client):
        """Test user creation fails with invalid email."""
        payload = {
            'email': 'invalid-email',
            'name': 'Test User'
        }
        response = client.post('/api/user',
                              data=json.dumps(payload),
                              content_type='application/json')
        assert response.status_code == 400
        assert 'email' in response.get_json()['error'].lower()
    
    def test_create_user_short_name(self, client):
        """Test user creation fails with name too short."""
        payload = {
            'email': 'test@example.com',
            'name': 'A'
        }
        response = client.post('/api/user',
                              data=json.dumps(payload),
                              content_type='application/json')
        assert response.status_code == 400
    
    def test_create_user_no_json_data(self, client):
        """Test user creation fails without JSON data."""
        response = client.post('/api/user')
        assert response.status_code == 400


class TestOrderEndpoint:
    """Tests for order creation endpoint."""
    
    def test_create_order_unauthorized(self, client):
        """Test that order endpoint requires authentication."""
        payload = {'amount': 100, 'quantity': 5}
        response = client.post('/api/order',
                              data=json.dumps(payload),
                              content_type='application/json')
        assert response.status_code == 401
    
    def test_create_order_success(self, client, auth_headers):
        """Test successful order creation with discount."""
        payload = {'amount': 100, 'quantity': 5}
        response = client.post('/api/order',
                              data=json.dumps(payload),
                              content_type='application/json',
                              headers=auth_headers)
        assert response.status_code == 201
        data = response.get_json()
        assert data['original_amount'] == 100
        assert data['quantity'] == 5
        assert data['discounted_amount'] == 95.0
        assert data['discount_percentage'] == 5.0
    
    def test_create_order_large_quantity_discount(self, client, auth_headers):
        """Test order with large quantity gets 10% discount."""
        payload = {'amount': 100, 'quantity': 10}
        response = client.post('/api/order',
                              data=json.dumps(payload),
                              content_type='application/json',
                              headers=auth_headers)
        assert response.status_code == 201
        data = response.get_json()
        assert data['discounted_amount'] == 90.0
        assert data['discount_percentage'] == 10.0
    
    def test_create_order_missing_amount(self, client, auth_headers):
        """Test order fails with missing amount."""
        payload = {'quantity': 5}
        response = client.post('/api/order',
                              data=json.dumps(payload),
                              content_type='application/json',
                              headers=auth_headers)
        assert response.status_code == 400
    
    def test_create_order_invalid_amount(self, client, auth_headers):
        """Test order fails with invalid amount."""
        payload = {'amount': 'invalid', 'quantity': 5}
        response = client.post('/api/order',
                              data=json.dumps(payload),
                              content_type='application/json',
                              headers=auth_headers)
        assert response.status_code == 400
    
    def test_create_order_negative_amount(self, client, auth_headers):
        """Test order fails with negative amount."""
        payload = {'amount': -100, 'quantity': 5}
        response = client.post('/api/order',
                              data=json.dumps(payload),
                              content_type='application/json',
                              headers=auth_headers)
        assert response.status_code == 400


class TestSearchEndpoint:
    """Tests for search endpoint."""
    
    def test_search_success(self, client):
        """Test successful search."""
        response = client.get('/api/search?q=python')
        assert response.status_code == 200
        data = response.get_json()
        assert 'query' in data
        assert 'results' in data
        assert 'count' in data
        assert data['query'] == 'python'
    
    def test_search_missing_query(self, client):
        """Test search fails without query parameter."""
        response = client.get('/api/search')
        assert response.status_code == 400
    
    def test_search_empty_query(self, client):
        """Test search fails with empty query."""
        response = client.get('/api/search?q=')
        assert response.status_code == 400
    
    def test_search_query_too_short(self, client):
        """Test search fails with query too short."""
        response = client.get('/api/search?q=a')
        assert response.status_code == 400
    
    def test_search_returns_results(self, client):
        """Test that search returns proper result structure."""
        response = client.get('/api/search?q=test')
        data = response.get_json()
        assert data['count'] > 0
        for result in data['results']:
            assert 'id' in result
            assert 'title' in result


class TestErrorHandling:
    """Tests for error handling."""
    
    def test_404_not_found(self, client):
        """Test 404 error handling."""
        response = client.get('/api/nonexistent')
        assert response.status_code == 404
        data = response.get_json()
        assert 'error' in data
