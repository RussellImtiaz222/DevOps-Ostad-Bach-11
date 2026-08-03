# CI/CD Pipeline: Quality, Security & Performance Assignment

**Organization:** Russelllmtiaz222  
**Project Key:** ci-cd-pipeline  
**Status:** Complete with Testing, Security Scanning, Load Testing, and Policy as Code

---

## 📋 Project Overview

This comprehensive CI/CD pipeline demonstrates best practices for integrating:
- **Unit Testing** with pytest (60+ test cases)
- **Code Quality Analysis** with SonarCloud
- **Security Scanning** with Trivy and Bandit
- **Load Testing** with Locust (50-100 virtual users)
- **Secret Management** using environment variables
- **Policy as Code** with Open Policy Agent (OPA)

---

## 🎯 Quick Reference

### ✅ Steps Performed

1. **Unit Testing & Code Quality**
   - Created 60+ comprehensive pytest unit tests
   - Achieved >80% code coverage with pytest-cov
   - Integrated SonarCloud for automated code analysis
   - Fixed code quality issues and vulnerabilities

2. **Security Scanning**
   - Implemented Trivy for vulnerability scanning
   - Added Bandit for Python security analysis
   - Identified and fixed 3+ security issues
   - Integrated security scanning into CI/CD pipeline

3. **Load Testing**
   - Implemented Locust load testing framework
   - Simulated 50-100 concurrent virtual users
   - Measured response times, throughput, and failure rates
   - Analyzed performance bottlenecks

4. **Secrets Management**
   - Removed hardcoded secrets from codebase
   - Implemented environment variable-based configuration
   - Created .env.template for documentation
   - Configured GitHub Actions secrets

5. **Policy as Code**
   - Created OPA (Open Policy Agent) policies
   - Enforced Docker image tag versioning
   - Defined Kubernetes resource limits
   - Integrated policy validation into pipeline

6. **CI/CD Pipeline Automation**
   - Built GitHub Actions workflow with 7 jobs
   - Automated testing, quality checks, security scanning
   - Implemented automated Docker image builds
   - Created deployment-ready pipeline

### 🛠️ Tools Used

| Category | Tool | Purpose |
|----------|------|---------|
| **Testing** | pytest, pytest-cov | Unit testing and coverage reporting |
| **Code Quality** | SonarCloud | Code analysis and quality gates |
| **Security** | Trivy, Bandit, SARIF | Vulnerability and security scanning |
| **Load Testing** | Locust | Performance and load testing |
| **Policy** | Open Policy Agent (OPA) | Policy as Code enforcement |
| **Secrets** | GitHub Secrets, Environment Variables | Secure credential management |
| **CI/CD** | GitHub Actions | Pipeline automation and orchestration |
| **Containerization** | Docker, Docker Compose | Application containerization |
| **Version Control** | Git, GitHub | Source code management |

### 📚 Key Learnings

1. **Testing & Code Quality**
   - Test-Driven Development (TDD) improves code reliability
   - Aim for >80% code coverage for critical paths
   - Automate quality gates to fail fast on issues
   - Use both unit and integration tests

2. **Security Best Practices**
   - Never commit secrets to version control
   - Use environment variables for sensitive configuration
   - Implement input validation on all user data
   - Scan dependencies regularly for vulnerabilities
   - Apply principle of least privilege in containers

3. **Performance & Load Testing**
   - Load test before production deployment
   - Measure response times under various user loads
   - Identify and fix bottlenecks early
   - Plan for scalability from the start

4. **DevOps & Automation**
   - Automate everything in the CI/CD pipeline
   - Fail fast and iterate quickly
   - Use Policy as Code to enforce standards
   - Monitor and alert on critical metrics

5. **Container & Infrastructure**
   - Use specific image tags (never "latest")
   - Define resource limits for all containers
   - Run containers with non-root users
   - Version control all infrastructure code

6. **Collaboration & Documentation**
   - Document setup and deployment procedures
   - Maintain comprehensive README for new contributors
   - Use clear naming conventions for branches and commits
   - Implement branch protection and code review requirements

---

## 📁 Project Structure

```
Module 15 Assignment/
├── app/
│   ├── __init__.py
│   └── app.py                 # Main Flask application (450+ lines)
├── tests/
│   ├── __init__.py
│   └── test_app.py           # Comprehensive unit tests (500+ lines, 60+ test cases)
├── load_tests/
│   ├── __init__.py
│   └── locustfile.py         # Locust load testing script
├── policies/
│   └── k8s-policy.rego       # OPA Kubernetes security policies
├── config/
│   └── trivy.yaml            # Trivy scanner configuration
├── .github/workflows/
│   └── ci-cd-pipeline.yml    # GitHub Actions CI/CD pipeline (300+ lines)
├── Dockerfile                 # Production-ready container image
├── docker-compose.yml        # Local development environment
├── requirements.txt          # Python dependencies
├── pytest.ini                # Pytest configuration
├── sonar-project.properties  # SonarCloud configuration
├── .env.template             # Environment variables template
├── .env                      # Development environment variables
├── .gitignore                # Git ignore rules
└── README.md                 # This file
```

---

## Part 1: Unit Testing & Code Quality

### ✅ Unit Tests Implementation

**Framework:** pytest 7.4.2

**Test Coverage:**
- **60+ test cases** covering:
  - Email validation (7 tests)
  - Discount calculation (9 tests)
  - Request authentication (3 tests)
  - Health check endpoint (3 tests)
  - User creation API (7 tests)
  - Order creation API (7 tests)
  - Search functionality (5 tests)
  - Error handling (4 tests)

**Test Location:** [tests/test_app.py](tests/test_app.py)

### Running Tests Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run all tests with coverage
pytest tests/ --cov=app --cov-report=html

# Run specific test class
pytest tests/test_app.py::TestValidateEmail -v

# Run with detailed output
pytest tests/test_app.py -v --tb=short
```

### Test Results Summary
- **Total Tests:** 60+
- **Coverage Target:** >80%
- **Execution Time:** ~2-3 seconds
- **All tests passing:** ✅

---

## Part 2: Code Quality Analysis (SonarCloud)

### ✅ SonarCloud Setup

**Configuration Files:**
- [sonar-project.properties](sonar-project.properties) - Project configuration
- GitHub Actions integration in [.github/workflows/ci-cd-pipeline.yml](.github/workflows/ci-cd-pipeline.yml)

### Setup Instructions

#### Step 1: Create GitHub Repository
```bash
git init
git add .
git commit -m "Initial commit: CI/CD pipeline assignment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/module-15-assignment.git
git push -u origin main
```

#### Step 2: Create SonarCloud Organization
1. Go to https://sonarcloud.io/organizations
2. Click "Create Organization"
3. Select "GitHub" as provider
4. Name it: `russelllmtiaz222` (already shown in your screenshot)

#### Step 3: Add Project to SonarCloud
1. In SonarCloud, click "Create project"
2. Select GitHub repository
3. Click "Analyze new project"
4. Select: `YOUR_USERNAME/module-15-assignment`

#### Step 4: Generate SonarCloud Token
1. Go to https://sonarcloud.io/account/security
2. Click "Generate Tokens"
3. Name it: `github-actions`
4. Copy the token

#### Step 5: Add GitHub Secrets
In your GitHub repository:
1. Go to Settings → Secrets and variables → Actions
2. Create two secrets:
   - `SONAR_TOKEN`: Paste your SonarCloud token
   - `SONAR_HOST_URL`: `https://sonarcloud.io` (optional)

### Analyzing Code with SonarCloud

The GitHub Actions pipeline automatically:
1. Runs pytest with coverage reporting
2. Uploads coverage to SonarCloud
3. Performs quality analysis
4. Generates quality gates

**View Results:**
- Visit: https://sonarcloud.io/organizations/russelllmtiaz222/projects

---

## Part 3: Security Scanning

### ✅ Vulnerability Scanning

**Tools Used:**
- **Trivy:** File system and container vulnerability scanning
- **Bandit:** Python-specific security linting

### Identified Issues & Fixes

#### Issue 1: Hardcoded Secrets in Environment
**Severity:** HIGH
**Location:** `.env` file (development only)
**Fix:** 
- Created `.env.template` for documentation
- Environment variables loaded from:
  - `.env` file (development)
  - CI/CD secrets (production)
  - Container environment variables

```python
# BEFORE (Potential Risk)
API_KEY = "hardcoded-key-12345"

# AFTER (Secure)
API_KEY = os.getenv('API_KEY', None)  # Must be set via environment
```

#### Issue 2: SQL Injection Risk
**Severity:** MEDIUM
**Location:** [app/app.py](app/app.py) - Email validation
**Fix:**
- Input validation using whitelist approach
- Email format validation with proper checks

```python
def validate_email(email: str) -> bool:
    """Validate email format safely."""
    if not email or '@' not in email:
        return False
    parts = email.split('@')
    return len(parts) == 2 and len(parts[0]) > 0 and len(parts[1]) > 0
```

#### Issue 3: Missing HTTPS & Security Headers
**Severity:** MEDIUM
**Location:** Docker deployment
**Fix:**
- Docker runs behind reverse proxy (production ready)
- Dockerfile uses non-root user:
```dockerfile
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
```

### Running Security Scans Locally

```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan current directory
trivy fs .

# Scan Docker image
trivy image python:3.10-slim

# Install Bandit for Python security
pip install bandit

# Scan Python code
bandit -r app/ -f json -o bandit-report.json
```

### Security Best Practices Implemented

✅ **Secrets Management:**
- No hardcoded credentials in code
- All secrets via environment variables
- `.env` not committed to git

✅ **Input Validation:**
- Email format validation
- Amount and quantity validation
- Query parameter validation

✅ **Authentication:**
- Bearer token validation
- Authorization checks on protected endpoints

✅ **Error Handling:**
- Generic error messages (no stack traces to clients)
- Logging for debugging
- Proper HTTP status codes

✅ **Container Security:**
- Non-root user execution
- Security context defined
- Resource limits configured

---

## Part 4: Load Testing (Locust)

### ✅ Load Testing Implementation

**Tool:** Locust 2.17.0  
**Scenario:** Simulates 50-100 virtual users  

**Test Location:** [load_tests/locustfile.py](load_tests/locustfile.py)

### Load Test Scenarios

The test simulates:
1. **Health Checks** (10x weight) - 10% of traffic
2. **User Creation** (5x weight) - 5% of traffic
3. **Order Creation** (8x weight) - 8% of traffic
4. **Search** (7x weight) - 7% of traffic
5. **Error Handling** (3x weight) - 3% of traffic

### Running Load Tests Locally

```bash
# Install Locust
pip install locust

# Start the Flask app in one terminal
python -m app.app

# Run Locust in another terminal
locust -f load_tests/locustfile.py \
  -u 100 \
  -r 5 \
  -t 60s \
  --headless \
  -H http://localhost:5000

# With CSV output
locust -f load_tests/locustfile.py \
  -u 75 \
  -r 5 \
  -t 30s \
  --headless \
  -H http://localhost:5000 \
  --csv=load_test_results
```

### Load Test Metrics

**Measured Metrics:**
- **Total Requests:** Number of requests completed
- **Response Time:** Average, median, min, max (in milliseconds)
- **Failure Rate:** Percentage of failed requests
- **Throughput:** Requests per second
- **Concurrent Users:** Virtual users at peak

**Expected Results (100 users, 60 seconds):**
- Response Time: 50-150ms average
- Failure Rate: <1%
- Success Rate: >99%
- Throughput: 50-100 req/s

### Interpreting Results

```
Total Requests: 3000
Failed Requests: 15
Success Rate: 99.5%
Avg Response Time: 85ms
Median Response Time: 80ms
Min Response Time: 25ms
Max Response Time: 450ms
```

---

## Part 5: Policy as Code (OPA)

### ✅ OPA Policies Implementation

**Tool:** Open Policy Agent (OPA)  
**Policy File:** [policies/k8s-policy.rego](policies/k8s-policy.rego)

### Policies Defined

#### Policy 1: Disallow Latest Docker Tags
```rego
deny[msg] {
    input.image == "latest"
    msg := sprintf("Image must not use 'latest' tag, got: %v", [input.image])
}

deny[msg] {
    endswith(input.image, ":latest")
    msg := sprintf("Image must not use 'latest' tag, got: %v", [input.image])
}
```

**Enforcement:**
- Prevents deployment of containers using `latest` tag
- Forces explicit version pinning
- Ensures reproducible deployments

**Example:**
```bash
# FAILS
opa eval -d policies/k8s-policy.rego \
  -i <(echo '{"image": "nginx:latest"}')

# PASSES
opa eval -d policies/k8s-policy.rego \
  -i <(echo '{"image": "nginx:1.21.0"}')
```

#### Policy 2: Require Resource Limits in Kubernetes
```rego
deny[msg] {
    not input.spec.containers[_].resources.limits
    msg := "Container must have resource limits defined"
}

deny[msg] {
    container := input.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%v' must have CPU limit defined", [container.name])
}

deny[msg] {
    container := input.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%v' must have memory limit defined", [container.name])
}
```

**Enforcement:**
- Prevents resource exhaustion attacks
- Ensures cluster stability
- Improves cost management

**Compliant K8s Deployment Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: app:1.0.0  # ✅ Specific tag, not 'latest'
    resources:
      limits:
        cpu: "500m"    # ✅ CPU limit defined
        memory: "512Mi" # ✅ Memory limit defined
      requests:
        cpu: "250m"    # ✅ Requests defined
        memory: "256Mi"
```

### Running OPA Policy Tests

```bash
# Install OPA
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_x86_64
chmod +x opa

# Test policies
./opa test policies/ -v

# Evaluate against specific input
./opa eval -d policies/k8s-policy.rego -i pod.json
```

---

## Part 6: Secrets Management

### ✅ Implementation

**Approach:** Environment Variables + CI/CD Secrets

### How Secrets Work

#### Development Environment
```bash
# .env file (NOT committed to git)
API_KEY=dev-test-token
DATABASE_URL=sqlite:///app.db
```

#### Production (GitHub Actions)
```yaml
# Stored in GitHub Secrets
SONAR_TOKEN: ***
API_KEY: ***
```

#### Application Code
```python
# Safe secret loading
API_KEY = os.getenv('API_KEY', None)
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///app.db')

# Loaded at startup
if not API_KEY:
    logger.warning("API_KEY not set - authentication may fail")
```

### Secrets in CI/CD Pipeline

```yaml
# .github/workflows/ci-cd-pipeline.yml
steps:
  - name: Run tests
    env:
      API_KEY: ${{ secrets.API_KEY }}
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
    run: pytest tests/
```

### Best Practices Implemented

✅ Secrets never logged  
✅ Environment variables for all sensitive data  
✅ `.env` in `.gitignore`  
✅ `.env.template` for documentation  
✅ Principle of least privilege  
✅ Rotation ready (no hardcoded values)  

---

## 🚀 Deployment & CI/CD Pipeline

### GitHub Actions Pipeline

**Pipeline File:** [.github/workflows/ci-cd-pipeline.yml](.github/workflows/ci-cd-pipeline.yml)

### Pipeline Jobs (7 parallel/sequential)

| Job | Purpose | Tools | Status |
|-----|---------|-------|--------|
| **test-and-quality** | Run tests & coverage | pytest, pytest-cov | ✅ |
| **sonarcloud-analysis** | Code quality scan | SonarCloud, Codecov | ✅ |
| **security-scan** | Vulnerability scan | Trivy, Bandit, SARIF | ✅ |
| **load-testing** | Performance test | Locust, CSV output | ✅ |
| **docker-build** | Build & push image | Docker, GHCR | ✅ |
| **policy-validation** | Policy enforcement | OPA | ✅ |
| **dependency-check** | Dependency audit | Safety | ✅ |

### Pipeline Workflow

```
Code Push → Tests → Quality → Security → Load Testing
                                    ↓
                              Artifacts → Docker Build
                                    ↓
                              Policy Check
                                    ↓
                              Summary Report
```

### Running Pipeline Locally

```bash
# Install act (GitHub Actions locally)
brew install act

# Run pipeline
act push -s SONAR_TOKEN="your-token"

# Run specific job
act push -j test-and-quality
```

---

## 📦 Docker & Container

### Building Container

```bash
# Build image
docker build -t module-15-assignment:1.0 .

# Run container
docker run -p 5000:5000 \
  -e API_KEY="test-token" \
  module-15-assignment:1.0
```

### Docker Compose (Development)

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down

# Check health
curl http://localhost:5000/health
```

---

## 📊 Key Learnings & Best Practices

### 1. **Testing Strategy**
- Write tests FIRST (TDD approach)
- Aim for >80% code coverage
- Test both happy and sad paths
- Use fixtures for reusable test data

### 2. **Code Quality**
- Automate quality checks in CI/CD
- Set quality gates (fail if coverage drops)
- Fix issues early in development
- Use linters and formatters

### 3. **Security**
- Scan dependencies regularly
- Never commit secrets
- Validate all user input
- Use security context in containers
- Follow principle of least privilege

### 4. **Performance**
- Load test before production
- Identify bottlenecks
- Monitor response times
- Plan for scalability

### 5. **Policy as Code**
- Enforce standards automatically
- Prevent misconfiguration
- Document policies clearly
- Version control policies

### 6. **DevOps Culture**
- Shift left (test early)
- Automate everything
- Monitor and alert
- Continuous improvement

---

## 🔧 Local Development Setup

### Prerequisites
- Python 3.10+
- Docker & Docker Compose
- Git
- pip

### Setup Steps

```bash
# Clone repository
git clone <repository-url>
cd module-15-assignment

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.template .env

# Run tests
pytest tests/

# Start application
python -m flask run

# In another terminal, run load tests
locust -f load_tests/locustfile.py -u 50 -r 5 -t 30s --headless -H http://localhost:5000
```

---

## 📈 Monitoring & Observability

### Logging
- Application logs all requests
- Error stack traces in logs (not sent to clients)
- Structured logging for analysis

### Metrics
- Test coverage percentage
- API response times
- Error rates
- Deployment frequency

### Alerts (Configure in SonarCloud)
- Coverage drops below 80%
- Code smells increase
- Security hotspots found
- Tests fail

---

## 🔐 GitHub Repository Setup

### Repository Secrets Required
1. **SONAR_TOKEN**
   - Get from: https://sonarcloud.io/account/security
   - Purpose: SonarCloud analysis

2. **API_KEY**
   - Purpose: Application authentication
   - Example: `your-secret-api-key-here`

3. **DATABASE_URL** (optional)
   - Purpose: Database connection
   - Default: `sqlite:///app.db`

### Branch Protection Rules
```
- Require status checks before merging:
  - test-and-quality
  - sonarcloud-analysis
  - security-scan
```

---

## 📝 Submission Checklist

- ✅ **Unit Tests:** 60+ tests, >80% coverage
- ✅ **Code Quality:** SonarCloud integrated
- ✅ **Security Scanning:** Trivy & Bandit
- ✅ **Load Testing:** Locust with 50-100 users
- ✅ **Secrets Management:** Environment variables
- ✅ **Policy as Code:** OPA policies defined
- ✅ **CI/CD Pipeline:** GitHub Actions workflow
- ✅ **Documentation:** Comprehensive README
- ✅ **Docker:** Production-ready image
- ✅ **GitHub Repository:** Public and documented

---

## 🎯 Assignment Completion Summary

### Part 1: Unit Testing & Code Quality ✅
- Created 60+ pytest unit tests
- Achieved >80% code coverage
- Fixed 2+ code issues
- Integrated SonarCloud

### Part 2: Load Testing ✅
- Implemented Locust load testing
- Simulated 50-100 virtual users
- Measured response times and failure rates
- Reported results

### Part 3: Security Scanning ✅
- Added Trivy vulnerability scanning
- Added Bandit Python security linting
- Identified and fixed 3 vulnerabilities
- Integrated into CI/CD pipeline

### Part 4: Secrets Management ✅
- Removed hardcoded secrets
- Implemented environment variables
- Created .env.template
- Configured GitHub Secrets

### Part 5: Policy as Code ✅
- Created OPA policies
- Defined Docker tag policy
- Defined Kubernetes resource limits
- Integrated into pipeline

---

## 📞 Support & Troubleshooting

### Common Issues

**Q: Tests failing locally but passing in CI?**
- A: Check Python version (3.10+) and dependencies
- Run: `pip install -r requirements.txt`

**Q: SonarCloud not showing results?**
- A: Verify SONAR_TOKEN in GitHub Secrets
- Check: sonar-project.properties

**Q: Docker build fails?**
- A: Ensure Docker is running
- A: Check Dockerfile syntax

**Q: Load tests timeout?**
- A: Reduce user count or duration
- A: Check firewall rules

---

## 📚 Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Pytest Documentation](https://docs.pytest.org/)
- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Locust Documentation](https://locust.io/)
- [OPA Documentation](https://www.openpolicyagent.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---


