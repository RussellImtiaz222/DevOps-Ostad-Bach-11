# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install dumb-init to handle signals properly
RUN apk add --no-cache dumb-init

COPY package*.json ./

RUN npm install --production

# Copy application files from builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY . .

EXPOSE 5000

ENV PORT=5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/api', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Run with dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]
CMD ["npm", "start"]