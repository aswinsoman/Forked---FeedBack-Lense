# Run Instructions — Docker Compose Only

This guide runs **both the API and MongoDB** using Docker Compose (recommended for assessors).

## Prerequisites
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose (bundled with Docker Desktop)

---

## 1) docker-compose.yml
Create a file named **`docker-compose.yml`** in project root with the following content:

```yaml
services:
  mongo:
    image: mongo:6
    restart: unless-stopped
    volumes:
      - mongo_data:/data/db

  app:
    build: .
    image: sit725-app:hd
    environment:
      PORT: "4000"
      MONGO_URI: "mongodb://mongo:27017/feedbackLense"
      NODE_ENV: "production"
    ports:
      - "4000:4000"
    depends_on:
      - mongo

volumes:
  mongo_data:
```

> Notes
> - The app listens on **PORT=4000** inside the container and is published on host port **4000**.
> - The app connects to Mongo using the service name `mongo` as hostname.

---

## 2) Build & Run
From the project root (where your `Dockerfile` and `docker-compose.yml` are located):

```bash
docker compose up --build
```
- This builds the app image and starts both containers.
- Stop with **Ctrl+C**. In a new terminal, you can also run `docker compose down`.

---

## 3) Access the API (port 4000)
- API info: **http://localhost:4000/api/v1**
- Health check: **http://localhost:4000/api/v1/health**
- Student endpoint (HD): **http://localhost:4000/api/student**

---

## 4) Expected `/api/student` output
```json
{
  "studentName": "Aswin Soman",
  "studentID": "225287418"
}
```

---

## 5) Quick Verification
```bash
# Show running services
docker compose ps

# Tail app logs
docker compose logs -f app

# Hit endpoints
curl http://localhost:4000/api/v1
curl http://localhost:4000/api/student

# Check Mongo is responsive from inside the mongo container
docker compose exec mongo mongosh --eval "db.adminCommand({ ping: 1 })"
# Expect: { ok: 1 }
```

---

## 6) Stop & Clean Up
```bash
# Stop and remove containers, network
docker compose down

# (Optional) also remove the named volume (data loss)
docker compose down -v
```
