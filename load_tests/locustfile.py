"""
Load testing script using Locust.
Simulates 50-100 virtual users hitting various endpoints.
Measures response time and failure rate.
"""

from locust import HttpUser, task, between, events
from statistics import mean, median
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Store metrics for reporting
class TestMetrics:
    """Store and calculate test metrics."""
    total_requests = 0
    failed_requests = 0
    response_times = []
    
    @classmethod
    def add_response_time(cls, time):
        cls.response_times.append(time)
        cls.total_requests += 1
    
    @classmethod
    def add_failure(cls):
        cls.failed_requests += 1
        cls.total_requests += 1
    
    @classmethod
    def get_stats(cls):
        if not cls.response_times:
            return {}
        return {
            'total_requests': cls.total_requests,
            'failed_requests': cls.failed_requests,
            'success_rate': ((cls.total_requests - cls.failed_requests) / cls.total_requests * 100) if cls.total_requests > 0 else 0,
            'avg_response_time': mean(cls.response_times),
            'median_response_time': median(cls.response_times),
            'min_response_time': min(cls.response_times),
            'max_response_time': max(cls.response_times),
        }


class APIUser(HttpUser):
    """Locust user class simulating API interactions."""
    
    # User waits between 1-3 seconds between tasks
    wait_time = between(1, 3)
    
    def on_start(self):
        """Initialize user session."""
        self.token = "test-token"
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
    
    @task(10)
    def health_check(self):
        """Task: Health check endpoint (weight: 10)."""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
                TestMetrics.add_response_time(response.elapsed.total_seconds() * 1000)
            else:
                response.failure(f"Unexpected status code: {response.status_code}")
                TestMetrics.add_failure()
    
    @task(5)
    def create_user(self):
        """Task: Create user endpoint (weight: 5)."""
        payload = {
            'email': f'user{self.user_id}@example.com',
            'name': f'Test User {self.user_id}'
        }
        with self.client.post(
            "/api/user",
            json=payload,
            catch_response=True
        ) as response:
            if response.status_code == 201:
                response.success()
                TestMetrics.add_response_time(response.elapsed.total_seconds() * 1000)
            else:
                response.failure(f"Unexpected status code: {response.status_code}")
                TestMetrics.add_failure()
    
    @task(8)
    def create_order(self):
        """Task: Create order endpoint (weight: 8)."""
        import random
        payload = {
            'amount': round(random.uniform(50, 500), 2),
            'quantity': random.randint(1, 15)
        }
        with self.client.post(
            "/api/order",
            json=payload,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 201:
                response.success()
                TestMetrics.add_response_time(response.elapsed.total_seconds() * 1000)
            else:
                response.failure(f"Unexpected status code: {response.status_code}")
                TestMetrics.add_failure()
    
    @task(7)
    def search(self):
        """Task: Search endpoint (weight: 7)."""
        import random
        queries = ['python', 'testing', 'security', 'performance', 'devops']
        query = random.choice(queries)
        with self.client.get(
            f"/api/search?q={query}",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
                TestMetrics.add_response_time(response.elapsed.total_seconds() * 1000)
            else:
                response.failure(f"Unexpected status code: {response.status_code}")
                TestMetrics.add_failure()
    
    @task(3)
    def invalid_request(self):
        """Task: Test error handling (weight: 3)."""
        with self.client.post(
            "/api/user",
            json={'name': 'No Email'},  # Missing required field
            catch_response=True
        ) as response:
            if response.status_code == 400:
                response.success()
                TestMetrics.add_response_time(response.elapsed.total_seconds() * 1000)
            else:
                response.failure(f"Expected 400, got {response.status_code}")
                TestMetrics.add_failure()


# Event hooks for detailed reporting
@events.request.add_listener
def on_request(request_type, name, response_time, response_length, exception, **kwargs):
    """Log each request for debugging."""
    if exception:
        logger.warning(f"{request_type} {name} failed: {exception}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Print summary statistics when test stops."""
    stats = TestMetrics.get_stats()
    logger.info("\n" + "="*60)
    logger.info("LOAD TEST SUMMARY")
    logger.info("="*60)
    logger.info(f"Total Requests: {stats.get('total_requests', 0)}")
    logger.info(f"Failed Requests: {stats.get('failed_requests', 0)}")
    logger.info(f"Success Rate: {stats.get('success_rate', 0):.2f}%")
    logger.info(f"Avg Response Time: {stats.get('avg_response_time', 0):.2f}ms")
    logger.info(f"Median Response Time: {stats.get('median_response_time', 0):.2f}ms")
    logger.info(f"Min Response Time: {stats.get('min_response_time', 0):.2f}ms")
    logger.info(f"Max Response Time: {stats.get('max_response_time', 0):.2f}ms")
    logger.info("="*60)


if __name__ == "__main__":
    logger.info("Locust load testing script")
    logger.info("Run with: locust -f load_tests/locustfile.py -u 100 -r 5 -t 60s --headless")
