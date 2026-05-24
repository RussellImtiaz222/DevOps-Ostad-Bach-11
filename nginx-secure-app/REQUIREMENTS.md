# System Requirements

## Minimum Requirements

- **OS:** Linux (Ubuntu 20.04+, Debian 10+, or WSL2 on Windows 10/11)
- **Disk Space:** 500MB
- **RAM:** 512MB minimum (1GB recommended)
- **Internet:** Required for package installation

## Software Requirements

### Required
- **Nginx:** 1.18+ (installed via package manager)
- **OpenSSL:** 1.1.1+ (for SSL certificate generation)
- **Bash:** 4.0+ (for shell scripts)

### Optional
- **Python:** 3.7+ (for backend test service)
- **Docker:** 20.10+ (for containerized testing)
- **Docker Compose:** 2.0+ (for easy orchestration)
- **curl:** 7.0+ (for testing - usually pre-installed)

## Installation by Environment

### Ubuntu/Debian (Native Linux)

```bash
# Update package list
sudo apt-get update

# Install core requirements
sudo apt-get install -y \
    nginx \
    openssl \
    curl \
    git

# Optional: Python for backend service
sudo apt-get install -y python3
```

### WSL2 (Windows Subsystem for Linux)

```bash
# In PowerShell (as Administrator)
wsl --install
wsl --install -d Ubuntu-22.04

# Then in WSL terminal
sudo apt-get update
sudo apt-get install -y \
    nginx \
    openssl \
    curl \
    git \
    python3
```

### Docker (Any OS)

```bash
# No installation needed if Docker is already installed
# Just run: docker-compose up -d
```

## Port Requirements

- **Port 80:** HTTP (must be available)
- **Port 443:** HTTPS/SSL (must be available)
- **Port 3000:** Backend service (must be available if testing reverse proxy)

### Check Port Availability

```bash
# Check if port is available
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :3000

# If ports are in use, you can:
# 1. Stop the other service
# 2. Or modify configuration to use different ports
```

## File System Requirements

- **Write Access:** To `/etc/nginx/`, `/var/www/`, `/var/log/nginx/`
- **Read Access:** From project directories
- **Recommended:** 2-3 GB free space for logs and testing

### Verify Permissions

```bash
# Check if you can write to nginx directories
sudo touch /etc/nginx/test_write
sudo rm /etc/nginx/test_write

# Check if nginx user can read config
sudo -u www-data test -r /etc/nginx/nginx.conf && echo "OK" || echo "FAIL"
```

## Browser Requirements (for GUI Testing)

- **Chrome/Chromium:** 90+ (recommended)
- **Firefox:** 88+ (recommended)
- **Safari:** 14+ (on macOS)
- **Edge:** 90+ (recommended)

**Note:** All modern browsers will show certificate warning for self-signed certs (this is expected and normal).

## Network Requirements

- **Localhost:** `127.0.0.1` must be available
- **Loopback Interface:** Must be enabled
- **DNS:** Not required (using localhost)

### Verify Loopback

```bash
ping 127.0.0.1
# Should respond without issues
```

## User Permissions

### For Native Linux/WSL2

Commands should be run as:
- **root** or **sudo** for: setup, SSL generation, Nginx start/stop
- **regular user** for: testing, accessing http/https

### Verify sudo access

```bash
sudo -v
# If successful, you have proper permissions
```

## CPU & Memory Recommendations

| Task | CPU | RAM |
|------|-----|-----|
| Basic Setup | 1 core | 256MB |
| With Backend Running | 2 cores | 512MB |
| Production-like Load | 4 cores | 1GB+ |

## Optional Tools (Recommended for Testing)

```bash
# Install additional testing tools
sudo apt-get install -y \
    net-tools          # netstat, ifconfig
    curl               # HTTP testing
    wget               # File download testing
    tmux               # Terminal multiplexing
    htop               # System monitoring
    openssl            # SSL/TLS testing
    jq                 # JSON parsing
```

## Storage Requirements

| Component | Space |
|-----------|-------|
| Nginx installation | ~20MB |
| OpenSSL | ~10MB |
| HTML files | <1MB |
| SSL certificates | <100KB |
| Log files (daily) | 1-5MB |
| Python runtime | ~50MB |
| **Total minimum** | **~500MB** |

## Pre-Setup Checklist

- [ ] OS is Ubuntu/Debian or WSL2
- [ ] Have `sudo` access or root password
- [ ] Ports 80, 443 available (or can modify)
- [ ] At least 500MB disk space free
- [ ] Internet connection for package download
- [ ] Git installed and repo cloned
- [ ] Terminal/console access

## Troubleshooting System Issues

### Common Compatibility Issues

**Issue:** Permission denied on `/etc/nginx/`
```bash
# Solution: Ensure you're using sudo
sudo command_here

# Or switch to root
sudo su -
```

**Issue:** Package not found
```bash
# Solution: Update package list
sudo apt-get update
sudo apt-get upgrade

# Then try installation again
```

**Issue:** Port already in use
```bash
# Solution: Find what's using it
sudo lsof -i :PORT_NUMBER

# If safe, kill the process
sudo kill -9 PID
```

**Issue:** Low disk space
```bash
# Solution: Clean up
sudo apt-get clean
sudo apt-get autoclean

# Check space
df -h
```

## Virtualization (If Using VM)

### VMware/VirtualBox Settings

- **Network:** Bridged or NAT (for port access)
- **CPU:** Minimum 2 vCPU
- **RAM:** Minimum 2GB
- **Disk:** Dynamic or 20GB static

### Hyper-V (Windows)

```powershell
# Create VM with suitable resources
New-VM -Name "nginx-server" -MemoryStartupBytes 1GB -BootDevice VirtualHardDisk
```

## Next Steps

Once system requirements are met:
1. Clone repository: `git clone <repo>`
2. Navigate: `cd nginx-secure-app`
3. Run setup: `sudo bash scripts/setup.sh`
4. Verify: `sudo bash scripts/test.sh`

For detailed instructions, see **README.md**
