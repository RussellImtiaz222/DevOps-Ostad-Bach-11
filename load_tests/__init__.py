"""
Load testing configuration and utilities.
"""

import os

# Load test configuration
LOAD_TEST_CONFIG = {
    'users': os.getenv('LOAD_TEST_USERS', 100),  # Virtual users
    'spawn_rate': os.getenv('LOAD_TEST_SPAWN_RATE', 5),  # Users spawned per second
    'duration': os.getenv('LOAD_TEST_DURATION', '60s'),  # Test duration
    'host': os.getenv('LOAD_TEST_HOST', 'http://localhost:5000'),
}
