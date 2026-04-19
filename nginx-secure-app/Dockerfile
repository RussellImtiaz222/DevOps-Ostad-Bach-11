FROM ubuntu:22.04

# Set environment
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    curl \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
RUN mkdir -p /var/www/secure-app

# Copy application files
COPY html/index.html /var/www/secure-app/
COPY nginx-config/secure-app.conf /etc/nginx/sites-available/

# Generate SSL certificate
RUN mkdir -p /etc/nginx/ssl && \
    openssl genrsa -out /etc/nginx/ssl/secure-app.key 2048 && \
    openssl req -new -x509 \
    -key /etc/nginx/ssl/secure-app.key \
    -out /etc/nginx/ssl/secure-app.crt \
    -days 365 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Enable site configuration
RUN ln -s /etc/nginx/sites-available/secure-app.conf /etc/nginx/sites-enabled/ && \
    rm -f /etc/nginx/sites-enabled/default

# Create entrypoint script
RUN echo "#!/bin/bash\n\
set -e\n\
\n\
echo '[*] Starting backend service...'\n\
python3 /app/backend/app.py &\n\
BACKEND_PID=\$!\n\
sleep 1\n\
\n\
echo '[*] Testing nginx configuration...'\n\
nginx -t\n\
\n\
echo '[*] Starting Nginx...'\n\
nginx -g 'daemon off;'\n\
" > /entrypoint.sh && chmod +x /entrypoint.sh

# Copy backend app
COPY backend/app.py /app/backend/app.py

# Expose ports
EXPOSE 80 443 3000

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f -k https://localhost/health || exit 1

# Run entrypoint
ENTRYPOINT ["/entrypoint.sh"]
