# Quick Start Guide

Get up and running in 5 minutes!

## 🚀 Local Development (2 minutes)

### 1. Setup
```bash
cd "c:\Users\iruss\Module 15 Assignment"
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Run Tests
```bash
pytest tests/ -v
```

### 3. Start Application
```bash
python -m app.app
```
Visit: http://localhost:5000/health

### 4. Load Testing (new terminal)
```bash
locust -f load_tests/locustfile.py -u 50 -r 5 -t 30s --headless -H http://localhost:5000
```

---

## 🐳 Docker Setup (3 minutes)

```bash
# Build and run
docker-compose up -d

# Check health
curl http://localhost:5000/health

# View logs
docker-compose logs -f app

# Stop
docker-compose down
```

---

## ☁️ SonarCloud Setup (5 minutes)

See [SONARCLOUD_SETUP.md](SONARCLOUD_SETUP.md)

Quick steps:
1. Create account at https://sonarcloud.io
2. Create organization: `russelllmtiaz222`
3. Get token from https://sonarcloud.io/account/security
4. Add to GitHub Secrets: `SONAR_TOKEN`

---

## 📊 View Results

- **Tests:** `pytest tests/` or GitHub Actions
- **Coverage:** `htmlcov/index.html` (open in browser)
- **Security:** GitHub Actions → security-scan → trivy-results.sarif
- **Load Test:** GitHub Actions → load-testing artifacts
- **Code Quality:** https://sonarcloud.io/organizations/russelllmtiaz222

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| [app/app.py](app/app.py) | Flask application (450 lines) |
| [tests/test_app.py](tests/test_app.py) | 60+ unit tests |
| [load_tests/locustfile.py](load_tests/locustfile.py) | Load testing (50-100 users) |
| [.github/workflows/ci-cd-pipeline.yml](.github/workflows/ci-cd-pipeline.yml) | CI/CD automation |
| [policies/k8s-policy.rego](policies/k8s-policy.rego) | OPA security policies |
| [Dockerfile](Dockerfile) | Container image |

---

## 🔒 Secrets Management

Development:
```bash
# .env (not committed)
API_KEY=dev-test-token
DATABASE_URL=sqlite:///app.db
```

Production (GitHub Secrets):
```
SONAR_TOKEN=***
API_KEY=***
```

---

## ✅ Assignment Completion

- ✅ **Part 1:** Unit tests (60+) + SonarCloud integration
- ✅ **Part 2:** Load testing with Locust (100 users)
- ✅ **Part 3:** Security scanning (Trivy + Bandit)
- ✅ **Part 4:** Secrets management (environment variables)
- ✅ **Part 5:** Policy as Code (OPA)

---

## 📚 Documentation

- [README.md](README.md) - Full documentation
- [SONARCLOUD_SETUP.md](SONARCLOUD_SETUP.md) - SonarCloud guide
- [GITHUB_SETUP.md](GITHUB_SETUP.md) - GitHub setup
- [SECURITY_REPORT.md](SECURITY_REPORT.md) - Security findings
- [LOAD_TEST_RESULTS.md](LOAD_TEST_RESULTS.md) - Performance data

---

## 🎯 Next Steps

1. **Push to GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Add Secrets** (GitHub Settings → Secrets)
   - `SONAR_TOKEN`
   - `SONAR_ORGANIZATION`

3. **Monitor Pipeline** (GitHub Actions tab)

4. **Review Results** (SonarCloud dashboard)

---

**Status:** ✅ Ready for Submission
