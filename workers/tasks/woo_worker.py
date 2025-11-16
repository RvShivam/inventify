"""
Simple worker that listens for `woo.store.connected` events and triggers:
  1) POST /internal/woo/stores/:id/sync_categories
  2) POST /internal/woo/stores/:id/register_webhooks

Environment variables:
  RABBITMQ_URL     (default: amqp://guest:guest@localhost:5672/)
  RABBITMQ_QUEUE   (default: worker.woo.category_sync)
  BACKEND_URL      (default: http://localhost:8080)
  SERVICE_TOKEN    (required) - Bearer token used to call internal endpoints
  PREFETCH_COUNT   (default: 1)
  MAX_CONNECT_RETRIES (default: 0 -> infinite retries)
"""

import json
import logging
import os
import time
import signal
import sys
import pika
import requests

# Config
RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
QUEUE_NAME = os.getenv("RABBITMQ_QUEUE", "worker.woo.category_sync")
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8080")
SERVICE_TOKEN = os.getenv("SERVICE_TOKEN")
PREFETCH_COUNT = int(os.getenv("PREFETCH_COUNT", "1"))
MAX_CONNECT_RETRIES = int(os.getenv("MAX_CONNECT_RETRIES", "0"))  # 0 = keep retrying
RECONNECT_WAIT = int(os.getenv("RECONNECT_WAIT", "3"))  # seconds between reconnect attempts
HTTP_TIMEOUT = int(os.getenv("HTTP_TIMEOUT", "30"))

if not SERVICE_TOKEN:
    logging.fatal("SERVICE_TOKEN environment variable is required")
    sys.exit(1)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

_stop = False

def get_ngrok_public_url():
    import requests
    r = requests.get("http://127.0.0.1:4040/api/tunnels").json()
    for t in r["tunnels"]:
        if t["public_url"].startswith("https://"):
            return t["public_url"]

def signal_handler(sig, frame):
    global _stop
    logging.info("signal received, shutting down...")
    _stop = True


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def call_backend_register_webhooks(store_id, delivery_url, topics):
    endpoint = f"/internal/woo/stores/{store_id}/register_webhooks"
    url = BACKEND_URL.rstrip("/") + endpoint
    headers = {
        "Service-Token": SERVICE_TOKEN,
        "Content-Type": "application/json",
    }
    payload = {"delivery_url": delivery_url, "topics": topics}
    try:
        resp = requests.post(url, json=payload, headers=headers, timeout=HTTP_TIMEOUT)
        return resp.status_code, resp.text
    except Exception as e:
        return 0, f"Request failed: {e}"

def call_backend_sync(store_id):
    endpoint = f"/internal/woo/stores/{store_id}/sync_categories"
    url = BACKEND_URL.rstrip("/") + endpoint
    headers = {
        "Service-Token": SERVICE_TOKEN,
        "Content-Type": "application/json",
    }
    try:
        resp = requests.post(url, headers=headers, timeout=HTTP_TIMEOUT)
        return resp.status_code, resp.text
    except Exception as e:
        return 0, f"Request failed: {e}"

def on_message(ch, method, properties, body):
    """
    Called when a message arrives.
    We expect a JSON event envelope like:
      {
        "event": "woo.store.connected",
        "version": 1,
        "timestamp": "2025-11-16T12:34:56Z",
        "store_id": 123,
        "organization_id": 42,
        "site_url": "https://example.com"
      }
    or nested under `payload`. Worker accepts both shapes (flexible).
    """
    delivery_tag = method.delivery_tag
    logging.info("received message delivery_tag=%s", delivery_tag)

    try:
        payload = json.loads(body)
    except Exception as e:
        logging.error("failed to parse message body: %s -- rejecting (no requeue)", e)
        ch.basic_reject(delivery_tag=delivery_tag, requeue=False)
        return

    # support different envelope shapes
    # 1) top-level store_id keys
    if "store_id" in payload:
        store_id = payload.get("store_id")
    else:
        # 2) nested payload
        store_id = None
        pl = payload.get("payload") if isinstance(payload, dict) else None
        if pl and isinstance(pl, dict):
            store_id = pl.get("store_id")

    if not store_id:
        logging.error("message missing store_id, rejecting (no requeue)")
        ch.basic_reject(delivery_tag=delivery_tag, requeue=False)
        return

    store_id = int(store_id)
    logging.info("handling woo.store.connected for store_id=%d", store_id)

    # 1) call sync_categories
    try:
        status, text = call_backend_sync(store_id)
    except Exception as e:
        logging.exception("error calling sync_categories; will nack+requeue")
        ch.basic_nack(delivery_tag=delivery_tag, requeue=True)
        time.sleep(1)
        return

    if status // 100 != 2:
        logging.error("sync_categories returned non-2xx: %d, body: %s", status, text)
        # treat it as transient so requeue; change if backend signals permanent error
        ch.basic_nack(delivery_tag=delivery_tag, requeue=True)
        return

    logging.info("sync_categories succeeded for store_id=%d", store_id)

    # 2) register webhooks (let backend decide default topics and delivery url)
    try:
        status, text = call_backend_register_webhooks(store_id)
    except Exception as e:
        logging.exception("error calling register_webhooks; will nack+requeue")
        ch.basic_nack(delivery_tag=delivery_tag, requeue=True)
        return

    if status // 100 != 2:
        logging.error("register_webhooks returned non-2xx: %d, body: %s", status, text)
        ch.basic_nack(delivery_tag=delivery_tag, requeue=True)
        return

    logging.info("register_webhooks succeeded for store_id=%d, acking message", store_id)
    ch.basic_ack(delivery_tag=delivery_tag)


def connect_and_consume():
    attempts = 0
    while not _stop:
        try:
            parameters = pika.URLParameters(RABBITMQ_URL)
            conn = pika.BlockingConnection(parameters)
            channel = conn.channel()
            # ensure durable exchange exists; worker doesn't create exchange args,
            # backend events package already created it but this is safe (idempotent).
            channel.exchange_declare(exchange="inventify.events", exchange_type="topic", durable=True)
            # declare durable queue
            channel.queue_declare(queue=QUEUE_NAME, durable=True)
            # bind queue to routing key for store.connected
            channel.queue_bind(queue=QUEUE_NAME, exchange="inventify.events", routing_key="woo.store.connected")
            # QoS
            channel.basic_qos(prefetch_count=PREFETCH_COUNT)
            logging.info("connected to RabbitMQ, consuming queue %s", QUEUE_NAME)

            for method, properties, body in channel.consume(QUEUE_NAME, inactivity_timeout=1):
                if _stop:
                    break
                if method is None:
                    # timed out (inactivity), loop back to check _stop
                    continue
                # Wrap message into on_message to handle ack/nack
                try:
                    on_message(channel, method, properties, body)
                except Exception:
                    logging.exception("unhandled exception while processing message; nack and requeue")
                    try:
                        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
                    except Exception:
                        pass

            # cancel consumer and close connection cleanly
            try:
                channel.cancel()
            except Exception:
                pass
            try:
                conn.close()
            except Exception:
                pass

            if _stop:
                break

        except Exception as e:
            attempts += 1
            logging.exception("connection/consume error: %s", e)
            if MAX_CONNECT_RETRIES > 0 and attempts >= MAX_CONNECT_RETRIES:
                logging.error("max connect retries reached (%d), exiting", MAX_CONNECT_RETRIES)
                break
            logging.info("reconnecting in %d seconds...", RECONNECT_WAIT)
            time.sleep(RECONNECT_WAIT)

    logging.info("worker exiting")


if __name__ == "__main__":
    logging.info("worker starting; RABBITMQ_URL=%s BACKEND_URL=%s", RABBITMQ_URL, BACKEND_URL)
    connect_and_consume()
