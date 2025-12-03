# Inventify

Inventify is a comprehensive inventory management system designed to streamline operations across multiple channels, including WooCommerce and ONDC.

## Project Structure

The project is organized into three main components:

- **[Client](./client)**: A Flutter-based mobile/web application for managing inventory, products, and settings.
- **[Server](./server)**: A Go (Golang) backend providing REST APIs and business logic.
- **[Workers](./workers)**: Python-based background workers for handling asynchronous tasks like WooCommerce syncing.

## Prerequisites

- **Go**: v1.21+
- **Flutter**: v3.x+
- **Python**: v3.10+
- **PostgreSQL**: Database
- **RabbitMQ**: Message broker for event-driven architecture

## Getting Started

1.  **Database**: Ensure PostgreSQL is running and a database is created.
2.  **RabbitMQ**: Ensure RabbitMQ is running.
3.  **Server**: Navigate to `server/` and follow the [Server README](./server/README.md).
4.  **Workers**: Navigate to `workers/` and follow the [Workers README](./workers/README.md).
5.  **Client**: Navigate to `client/` and follow the [Client README](./client/README.md).

## Architecture

Inventify uses an event-driven architecture. The server publishes events (e.g., `product.created`, `woo.store.connected`) to RabbitMQ. Background workers consume these events to perform heavy lifting or external API integrations, ensuring the core API remains fast and responsive.
