# publish_test_event.py
import pika, json, os
from dotenv import load_dotenv
from pathlib import Path

dotenv_path = Path('D:\inventify\server\.env')
load_dotenv(dotenv_path = dotenv_path)

RABBITMQ_URL = os.getenv("RABBITMQ_URL","amqp://guest:guest@localhost:5672/")
params = pika.URLParameters(RABBITMQ_URL)
conn = pika.BlockingConnection(params)
ch = conn.channel()
ch.exchange_declare(exchange="inventify.events", exchange_type="topic", durable=True)
payload = {
  "event": "woo.store.connected",
  "version": 1,
  "timestamp": "2025-11-16T00:00:00Z",
  "store_id": 123,
  "organization_id": 1,
  "site_url": "https://example.com"
}
ch.basic_publish(exchange="inventify.events", routing_key="woo.store.connected", body=json.dumps(payload), properties=pika.BasicProperties(delivery_mode=2))
print("published")
conn.close()
