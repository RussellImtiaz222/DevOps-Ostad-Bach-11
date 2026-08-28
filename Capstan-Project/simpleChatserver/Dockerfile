# ---- Build stage ----
FROM node:20-alpine AS build
WORKDIR /app

COPY Capstan-Project/simpleChatserver/package*.json ./
RUN npm install

COPY Capstan-Project/simpleChatserver/tsconfig.json ./
COPY Capstan-Project/simpleChatserver/src ./src
RUN npm run build

# ---- Production stage ----
FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

COPY Capstan-Project/simpleChatserver/package*.json ./
RUN npm install --omit=dev

COPY --from=build /app/dist ./dist

EXPOSE 5000

USER node

CMD ["node", "dist/server.js"]
