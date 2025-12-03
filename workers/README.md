# Inventify Workers

Background workers for handling asynchronous tasks, built with Python.

## Workers

- **WooWorker** (`tasks/woo_worker.py`):
    - Listens for `product.created` to sync products to WooCommerce.
    - Listens for `woo.store.connected` to sync categories and register webhooks.

## Setup

1.  **Python**: Ensure Python 3.10+ is installed.
2.  **Virtual Environment** (Recommended):
    ```bash
    python -m venv venv
    source venv/bin/activate  # Windows: venv\Scripts\activate
    ```
3.  **Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Environment Variables**:
    The workers load environment variables from `../server/.env` by default, or you can set them explicitly.
    - `RABBITMQ_URL`
    - `BACKEND_URL`
    - `SERVICE_TOKEN`

## Running

Run the worker:
```bash
python tasks/woo_worker.py
```

## Architecture

Workers consume messages from RabbitMQ topics. For operations requiring database updates, they call protected "Internal APIs" on the main Go server using a `Service-Token` for authentication.
