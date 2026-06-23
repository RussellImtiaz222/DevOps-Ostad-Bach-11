# Module 10 Assignment: Docker Compose Deployment

This project contains a simple Express.js application that is containerized with Docker and run alongside an Nginx container using Docker Compose.

## Prerequisites

- Docker Desktop
- Docker Compose
- Docker Hub account

## Local Node.js Commands

```bash
npm install
npm start
```

The Express app runs on port `5000` inside the container.

## Docker Files

- `Dockerfile` builds the Express.js app image.
- `.dockerignore` keeps unnecessary files out of the Docker build context.
- `docker-compose.yml` starts two services:
  - `nginx` from the `nginx:alpine` image
  - `express-app` built from this repository's `Dockerfile`

The Compose file starts the Express app after Nginx and exposes the Express app on port `8080`.

## Run With Docker Compose

From the project folder, run:

```bash
docker compose up -d --build
```

Check the running containers:

```bash
docker compose ps
```

Open the app in a browser:

```text
http://localhost:8080
```

Test the API route:

```text
http://localhost:8080/api
```

Expected API response:

```json
{"message":"Hello World changes"}
```

## Push Image to Docker Hub

Log in to Docker Hub:

```bash
docker login
```

Tag the local image. Replace `YOUR_DOCKERHUB_USERNAME` with your Docker Hub username:

```bash
docker tag module-10-express-app:latest YOUR_DOCKERHUB_USERNAME/module-10-express-app:latest
```

Push the image:

```bash
docker push YOUR_DOCKERHUB_USERNAME/module-10-express-app:latest
```

## Stop the Containers

```bash
docker compose down
```
