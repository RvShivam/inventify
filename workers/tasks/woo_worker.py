"""
WooCommerce Worker

Listens for `woo.store.connected` events and triggers:
  1) POST /internal/woo/stores/:id/sync_categories
  2) POST /internal/woo/stores/:id/register_webhooks

Environment variables:
  RABBITMQ_URL       (default amqp://guest:guest@localhost:5672/)
  BACKEND_URL        (default http://localhost:8080)
  SERVICE_TOKEN      (required)
  PREFETCH_COUNT     (default 1)
  QUEUE_NAME         (default worker.woo.category_sync)
"""

import json
import logging
import os
import time
import signal
import sys
import pika
import requests
from dotenv import load_dotenv
from pathlib import Path

dotenv_path = Path('D:\inventify\server\.env')
load_dotenv(dotenv_path = dotenv_path)

# ===== Worker Configuration =====

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
QUEUE_NAME = os.getenv("RABBITMQ_QUEUE", "worker.woo.category_sync")
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8080")
SERVICE_TOKEN = os.getenv("SERVICE_TOKEN")

PREFETCH_COUNT = int(os.getenv("PREFETCH_COUNT", "1"))
HTTP_TIMEOUT = int(os.getenv("HTTP_TIMEOUT", "30"))
RECONNECT_WAIT = int(os.getenv("RECONNECT_WAIT", "3"))

if not SERVICE_TOKEN:
    sys.exit("❌ SERVICE_TOKEN environment variable is required")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

_stop = False

# ===========================================================
# Helpers
# ===========================================================

def get_ngrok_public_url():
    """
    Detect ngrok https public URL using the local API (4040).
    Returns https://xxxx.ngrok-free.app if running, else None.
    """
    try:
        r = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=2)
        data = r.json()

        for t in data.get("tunnels", []):
            url = t.get("public_url", "")
            if url.startswith("https://"):
                return url
        return None

    except Exception:
        return None


def call_backend_sync(store_id):
    url = f"{BACKEND_URL.rstrip('/')}/internal/woo/stores/{store_id}/sync_categories"
    headers = {
        "Service-Token": SERVICE_TOKEN,
        "Content-Type": "application/json",
    }
    try:
        resp = requests.post(url, headers=headers, timeout=HTTP_TIMEOUT)
        return resp.status_code, resp.text
    except Exception as e:
        return 0, f"Request failed: {e}"


def call_backend_register_webhooks(store_id, delivery_url=None, topics=None):
    url = f"{BACKEND_URL.rstrip('/')}/internal/woo/stores/{store_id}/register_webhooks"
    headers = {
        "Service-Token": SERVICE_TOKEN,
        "Content-Type": "application/json",
    }

    payload = {}
    if delivery_url:
        payload["delivery_url"] = delivery_url
    if topics:
        payload["topics"] = topics

    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=HTTP_TIMEOUT)
        return resp.status_code, resp.text
    except Exception as e:
        return 0, f"Request failed: {e}"


# ===========================================================
# Message Handler
# ===========================================================

MAX_RETRIES = 5

def on_message(ch, method, properties, body):
    delivery_tag = method.delivery_tag
    logging.info("📨 Received message")

    try:
        msg = json.loads(body)
    except Exception:
        logging.error("Invalid JSON; rejecting.")
        ch.basic_reject(delivery_tag=delivery_tag, requeue=False)
        return

    # Get retry count from headers
    headers = properties.headers or {}
    retry_count = headers.get("x-retry-count", 0)

    store_id = msg.get("store_id") or msg.get("payload", {}).get("store_id")
    if not store_id:
        logging.error("Missing store_id; rejecting.")
        ch.basic_reject(delivery_tag=delivery_tag, requeue=False)
        return

    store_id = int(store_id)

    # =======================================================
    # 1. Sync Categories
    # =======================================================
    logging.info(f"🔄 Syncing categories for store_id={store_id} (Attempt {retry_count + 1}/{MAX_RETRIES + 1})")

    status, text = call_backend_sync(store_id)
    
    # Check for failure conditions that warrant a retry
    needs_retry = False
    if status == 0:
        logging.error("sync_categories network error: %s", text)
        needs_retry = True
    elif status // 100 != 2 and status not in [401, 403, 404]:
        logging.error("sync_categories failed (%d): %s", status, text)
        needs_retry = True
    elif status in [401, 403, 404]:
        logging.error("sync_categories fatal error (%d): %s; rejecting", status, text)
        ch.basic_reject(delivery_tag=delivery_tag, requeue=False)
        return

    if needs_retry:
        if retry_count < MAX_RETRIES:
            logging.info(f"Requeuing message for retry {retry_count + 1}...")
            time.sleep(1) # Basic backoff
            
            # Publish new message with incremented retry count
            new_headers = headers.copy()
            new_headers["x-retry-count"] = retry_count + 1
            
            ch.basic_publish(
                exchange=method.exchange,
                routing_key=method.routing_key,
                body=body,
                properties=pika.BasicProperties(
                    headers=new_headers,
                    delivery_mode=2 # Persistent
                )
            )
            ch.basic_ack(delivery_tag=delivery_tag)
        else:
            logging.error("❌ Max retries exceeded for sync_categories. Dropping message.")
            ch.basic_ack(delivery_tag=delivery_tag)
        return

    logging.info("✅ Category sync complete")

    # =======================================================
    # 2. Register webhooks
    # =======================================================
    logging.info("🔗 Registering Woo webhooks...")

    ngrok_url = get_ngrok_public_url()
    if ngrok_url:
        delivery_url = ngrok_url.rstrip("/") + "/webhooks/woo"
        logging.info(f"Using ngrok delivery URL: {delivery_url}")
    else:
        delivery_url = None
        logging.warning("⚠ No ngrok URL detected; backend must use fallback delivery URL")

    topics = [
        "order.created",
        "order.updated",
    ]

    status, text = call_backend_register_webhooks(store_id, delivery_url, topics)
    
    # Check for failure conditions that warrant a retry
    needs_retry = False
    if status == 0:
        logging.error("register_webhooks network error: %s", text)
        needs_retry = True
    elif status // 100 != 2 and status not in [401, 403, 404]:
        logging.error("register_webhooks failed (%d): %s", status, text)
        needs_retry = True
    elif status in [401, 403, 404]:
        logging.error("register_webhooks fatal error (%d): %s; rejecting", status, text)
        ch.basic_reject(delivery_tag=delivery_tag, requeue=False)
        return

    if needs_retry:
        if retry_count < MAX_RETRIES:
            logging.info(f"Requeuing message for retry {retry_count + 1}...")
            time.sleep(1)
            
            new_headers = headers.copy()
            new_headers["x-retry-count"] = retry_count + 1
            
            ch.basic_publish(
                exchange=method.exchange,
                routing_key=method.routing_key,
                body=body,
                properties=pika.BasicProperties(
                    headers=new_headers,
                    delivery_mode=2
                )
            )
            ch.basic_ack(delivery_tag=delivery_tag)
        else:
            logging.error("❌ Max retries exceeded for register_webhooks. Dropping message.")
            ch.basic_ack(delivery_tag=delivery_tag)
        return

    logging.info("✅ Webhooks registered successfully")
    ch.basic_ack(delivery_tag=delivery_tag)


# ===========================================================
# RabbitMQ Connection Loop
# ===========================================================

def connect_and_consume():
    while not _stop:
        try:
            conn = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
            ch = conn.channel()

            ch.exchange_declare(
                exchange="inventify.events",
                exchange_type="topic",
                durable=True,
            )

            ch.queue_declare(queue=QUEUE_NAME, durable=True)
            ch.queue_bind(
                queue=QUEUE_NAME,
                exchange="inventify.events",
                routing_key="woo.store.connected",
            )

            ch.basic_qos(prefetch_count=PREFETCH_COUNT)

            logging.info(f"🐇 Connected to RabbitMQ. Listening on queue '{QUEUE_NAME}'...")

            for method, properties, body in ch.consume(QUEUE_NAME, inactivity_timeout=1):
                if _stop:
                    break
                if method:
                    on_message(ch, method, properties, body)

            try:
                ch.cancel()
            except Exception:
                pass
            conn.close()

        except Exception as e:
            logging.error(f"RabbitMQ connection error: {e}")
            time.sleep(RECONNECT_WAIT)

    logging.info("Worker shutting down.")


# ===========================================================
# Entrypoint
# ===========================================================

def signal_handler(sig, frame):
    global _stop
    logging.info("Signal received, shutting down...")
    _stop = True

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

if __name__ == "__main__":
    logging.info(f"🚀 Woo Worker Starting")
    logging.info(f"RabbitMQ: {RABBITMQ_URL}")
    logging.info(f"Backend: {BACKEND_URL}")
    connect_and_consume()
