# Inventify Server

The backend server for Inventify, built with Go (Golang) and Gin framework.

## Features

- **REST API**: Endpoints for products, orders, auth, and settings.
- **Event Bus**: Publishes events to RabbitMQ.
- **Database**: Uses GORM with PostgreSQL.
- **Internal APIs**: Protected endpoints for workers.

## Setup

1.  **Environment Variables**:
    Create a `.env` file in this directory (copy from `.env.example` if available).
    ```env
    DB_HOST=localhost
    DB_USER=postgres
    DB_PASSWORD=password
    DB_NAME=inventify
    DB_PORT=5432
    RABBITMQ_URL=amqp://guest:guest@localhost:5672/
    APP_SECRET_KEY=your-32-byte-secret-key
    SERVICE_TOKEN=your-service-token-for-workers
    ```

2.  **Dependencies**:
    ```bash
    go mod download
    ```

## Running

```bash
go run cmd/server/main.go
```
(Adjust the path to `main.go` if it's located elsewhere, e.g., `main.go` in root of server or `cmd/api/main.go`).

## Key Directories

- `internal/handlers`: HTTP request handlers.
- `internal/models`: Database models.
- `internal/services`: Business logic.
- `internal/events`: RabbitMQ publisher/consumer logic.
