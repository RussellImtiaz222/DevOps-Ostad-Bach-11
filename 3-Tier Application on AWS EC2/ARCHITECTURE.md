# Architecture Documentation - BMI Health Tracker

## 🎯 Application Overview

**BMI Health Tracker** is a production-ready 3-tier full-stack web application deployed on a **single Ubuntu 22.04 LTS EC2 instance** with proper architectural separation of concerns.

| Layer | Technology | Runs on |
|-------|-----------|---------|
| Frontend | React 18 + Vite 5 + Chart.js 4 | Nginx (static) |
| Backend | Node.js 20 LTS + Express 4 | PM2 port 3000 |
| Database | PostgreSQL 14 | localhost:5432 |

---

## 🏗️ System Overview (Single EC2 Instance)

This is a 3-tier application deployed on **1 single AWS EC2 instance** with proper architectural separation of concerns through local service boundaries.

```
┌──────────────────────────────────────────────────┐
│              End User / Browser                   │
└────────────────┬─────────────────────────────────┘
                 │ HTTP/HTTPS
                 │ (Port 80/443)
        ┌────────▼──────────────┐
        │   PRESENTATION LAYER  │
        │   ────────────────    │
        │   Nginx Web Server    │
        │   ─ React SPA (dist)  │
        │   ─ Port 80/443       │
        │   ─ Reverse Proxy     │
        │   ─ Static Assets     │
        │   ─ Security Headers  │
        └────────┬──────────────┘
                 │ /api/*
                 │ (localhost:3000)
        ┌────────▼──────────────┐
        │  APPLICATION LAYER    │
        │  ────────────────     │
        │  Node.js 20 LTS       │
        │  Express 4            │
        │  PM2 Process Manager  │
        │  ─ REST API Endpoints │
        │  ─ Port 3000 (Internal)
        │  ─ Business Logic     │
        │  ─ Request Handling   │
        │  ─ Data Validation    │
        └────────┬──────────────┘
                 │ Port 5432
                 │ (localhost)
        ┌────────▼──────────────┐
        │   DATABASE LAYER      │
        │   ────────────────    │
        │   PostgreSQL 14       │
        │   ─ Persistent Data   │
        │   ─ Port 5432         │
        │   ─ Measurements DB   │
        │   ─ Audit Logging     │
        │   ─ Encryption (SCRAM)│
        └───────────────────────┘
```

---

## 📊 System Components

### Layer 1: Presentation (Frontend)
**Technology:** React 18 + Vite 5 + Chart.js 4  
**Server:** Nginx  
**Port:** 80 (HTTP) / 443 (HTTPS optional)  
**Location:** `/var/www/bmi-health-tracker` (static files)  
**Service Management:** systemd  

**Responsibilities:**
- Serve React Single Page Application (SPA)
- Route all non-file requests to `index.html`
- Proxy API requests (`/api/*`) to Node.js backend on port 3000
- Cache static assets (CSS, JS, images)
- Serve security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)

**Nginx Configuration:**
```nginx
location / {
    try_files $uri $uri/ /index.html;
}

location /api/ {
    proxy_pass http://127.0.0.1:3000;
}
```

---

### Layer 2: Application (Backend)
**Technology:** Node.js 20 LTS + Express 4  
**Process Manager:** PM2  
**Port:** 3000 (internal only)  
**Location:** `/opt/bmi-app/backend`  
**Environment:** Production  
**Entry Point:** `src/server.js`

**Responsibilities:**
- RESTful API endpoints for measurements
- Request validation and sanitization
- Business logic (BMI calculations)
- Database query handling
- Error handling and logging
- CORS support
- Security middleware (Helmet)
- Request logging (Morgan)

**Key Features:**
- Graceful shutdown on SIGTERM
- Automatic restart via PM2
- Environment variable configuration
- Database connection pooling (via pg library)

**Main Routes:**
```
GET  /api/health                    - Health check
GET  /api/measurements              - List all measurements
POST /api/measurements              - Create new measurement
GET  /api/measurements/:id          - Get single measurement
PUT  /api/measurements/:id          - Update measurement
DELETE /api/measurements/:id        - Delete measurement
GET  /api/measurements/stats/summary - Get statistics
```

---

### Layer 3: Database
**Technology:** PostgreSQL 14  
**Port:** 5432 (localhost only)  
**Database Name:** bmidb  
**User:** bmi_user  
**Location:** System service managed by systemd  
**Service Management:** systemctl

**Responsibilities:**
- Persistent data storage
- Data integrity and validation
- Audit logging
- Index optimization
- Backup and recovery (Day-2 operations)

**Database Schema:**
```sql
measurements (
  - id UUID (Primary Key)
  - height DECIMAL (meters)
  - weight DECIMAL (kilograms)
  - bmi DECIMAL (calculated)
  - measurement_date DATE
  - notes TEXT
  - created_at TIMESTAMP
  - updated_at TIMESTAMP
)

audit_logs (
  - id UUID (Primary Key)
  - action VARCHAR (INSERT/UPDATE/DELETE)
  - table_name VARCHAR
  - record_id UUID
  - old_values JSONB
  - new_values JSONB
  - created_at TIMESTAMP
)
```

**Key Features:**
- Auto-update timestamps via triggers
- Automatic audit logging
- BMI calculation stored procedure
- Indexes on frequently queried columns
- UUID primary keys for distributed systems

---

## 🔄 Request Flow

1. **User accesses `http://YOUR_EC2_IP`**
   - Browser connects to Nginx on port 80

2. **Nginx serves React SPA**
   - Static HTML/JS/CSS files sent to browser
   - Browser renders React application

3. **Frontend makes API call: `GET /api/measurements`**
   - Nginx intercepts request matching `/api/*`
   - Request forwarded to Node.js backend (port 3000)

4. **Node.js processes request**
   - Express middleware validates request
   - Business logic executes
   - Database query prepared

5. **Database executes query**
   - PostgreSQL retrieves data
   - Triggers audit logging
   - Returns results to Node.js

6. **Response flows back to frontend**
   - Node.js sends JSON response
   - Nginx forwards to browser
   - React updates UI

---

## 🔐 Security Architecture

### Network Isolation
- All services communicate on `localhost` (127.0.0.1)
- Only Nginx exposed to external traffic (port 80/443)
- Node.js port 3000 only accessible from localhost
- PostgreSQL port 5432 only accessible from localhost
- SSH access (port 22) restricted by security group

### Authentication & Encryption
- PostgreSQL SCRAM password authentication
- Environment variables for sensitive credentials (`.env` file)
- HTTPS support via Let's Encrypt (optional)
- Security headers in HTTP responses

### Data Protection
- Audit logging for all database modifications
- Triggers prevent direct timestamp manipulation
- Input validation on API endpoints
- Helmet middleware for XSS/clickjacking protection
- CORS configured to allow specified origins

---

## 📈 Scalability Considerations

### Current Setup
- Single-instance deployment suitable for:
  - Development/Testing
  - Small production workloads (< 1000 concurrent users)
  - Learning/Educational purposes

### Future Scaling Options
1. **Horizontal Scaling (Multiple Instances)**
   - Load Balancer in front of multiple web instances
   - Shared RDS database or read replicas
   - Session state management (Redis/ElastiCache)

2. **Vertical Scaling (Larger Instance)**
   - Upgrade to t3.large or larger
   - More CPU, memory, and network bandwidth

3. **Database Optimization**
   - Connection pooling (PgBouncer)
   - Read replicas
   - Caching layer (Redis)

---

## 🛠️ Technologies & Versions

| Component | Technology | Version | Port |
|-----------|-----------|---------|------|
| **Frontend** | React | 18.x | 80 |
| | Vite | 5.x | 80 |
| | Chart.js | 4.x | 80 |
| **Web Server** | Nginx | Latest | 80/443 |
| **Backend** | Node.js | 20 LTS | 3000 |
| | Express | 4.x | 3000 |
| | PM2 | 5.x | N/A |
| **Database** | PostgreSQL | 14 | 5432 |

---

## 📝 Deployment Path

```
1. EC2 Instance Launch (Ubuntu 22.04 LTS, t2.micro)
   ↓
2. System Dependencies (curl, git, build-essential)
   ↓
3. Database Layer (PostgreSQL 14)
   ↓
4. Backend Layer (Node.js 20 + PM2)
   ↓
5. Frontend Layer (React Build + Nginx)
   ↓
6. Health Checks & Verification
```

---

## ✅ Health Check Endpoints

- **Backend Health:** `curl http://localhost:3000/api/health`
- **Frontend Health:** `curl http://localhost/`
- **Database Health:** `psql -U bmi_user -d bmidb -c "SELECT 1;"`
- **PM2 Status:** `pm2 status`

---

## 📌 Key Differences from Previous Multi-Instance Architecture

| Aspect | Multi-Instance | Current Single-Server |
|--------|-----------|----------------------|
| **Instances** | 3 separate EC2 | 1 EC2 instance |
| **Database** | Separate private instance | Same instance |
| **App Servers** | 2+ web servers | Single backend process |
| **Network** | VPC + routing | localhost |
| **Load Balancer** | ALB required | Nginx built-in |
| **Scaling** | Horizontal (add instances) | Vertical (larger instance) |
| **Cost** | Higher ($$$) | Lower ($) |
| **Complexity** | Complex (multi-instance) | Simple (single-server) |
| **Suitable For** | Production (HA/DR) | Dev/Testing/Small Prod |

---

**Version:** 5.0  
**Last Updated:** April 19, 2026  
**Application:** BMI Health Tracker  
**Deployment Model:** Single EC2 Instance (Ubuntu 22.04 LTS)

