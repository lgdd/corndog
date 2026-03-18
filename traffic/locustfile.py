"""
Locust traffic generator for the Corndog security demo.

Routes all traffic through corndog-web-ui (Nginx) so every request
produces a complete distributed trace across the Angular proxy and
backend services (corndog-menu, corndog-orders, corndog-admin).

Failure scenarios use the same security payloads a demoer would type
during a live presentation — SQL injection, command injection, stored
XSS, and broken-auth access.  Each scenario has its own Locust task
with a descriptive name tag.

Configure via environment variables:
    TRAFFIC_TARGET      base URL of the entry point (default http://corndog-web-ui:80)
    TRAFFIC_LATENCY_MS  extra sleep per request in ms (default 0)
"""

import math
import os
import random
import time

from locust import HttpUser, between, constant_pacing, task

LATENCY_MS = int(os.getenv("TRAFFIC_LATENCY_MS", "0"))

MENU_ITEM_IDS = [1, 2, 3, 4]

CUSTOMER_NAMES = [
    "Casey Jones", "Pat Kim", "Jordan Lee", "Alex Rivera",
    "Sam Chen", "Dana Park", "Morgan Blake", "Riley Quinn",
]

XSS_PAYLOAD = '<img src=x onerror=alert("XSS")>'
SQLI_PAYLOAD = "' OR 1=1--"
CMD_INJECTION_RECEIPT = "txt;id"
CMD_INJECTION_EXPORT = "orders.csv; cat /etc/passwd"

HEADERS = {"User-Agent": "dd-demo-traffic/1.0"}


def _extra_latency():
    if LATENCY_MS > 0:
        time.sleep(LATENCY_MS / 1000)


def _random_order_payload(special_instructions=""):
    qty = random.randint(1, 3)
    item_id = random.choice(MENU_ITEM_IDS)
    prices = {1: 4.99, 2: 5.99, 3: 6.49, 4: 5.49}
    return {
        "customerName": random.choice(CUSTOMER_NAMES),
        "items": [{"menu_item_id": item_id, "quantity": qty}],
        "specialInstructions": special_instructions,
        "totalPrice": round(prices[item_id] * qty, 2),
    }


class CorndogUser(HttpUser):
    wait_time = between(0.5, 2.0)

    # ── Golden-path tasks ──────────────────────────────────────

    @task(10)
    def browse_menu(self):
        """GET /api/menu — list all menu items."""
        self.client.get(
            "/api/menu",
            headers=HEADERS,
            name="GET /api/menu [golden]",
        )
        _extra_latency()

    @task(3)
    def view_single_item(self):
        """GET /api/menu/{id} — view a specific menu item."""
        item_id = random.choice(MENU_ITEM_IDS)
        self.client.get(
            f"/api/menu/{item_id}",
            headers=HEADERS,
            name="GET /api/menu/{id} [golden]",
        )
        _extra_latency()

    @task(8)
    def place_order(self):
        """POST /api/orders — place a normal corndog order."""
        self.client.post(
            "/api/orders",
            json=_random_order_payload(),
            headers=HEADERS,
            name="POST /api/orders [golden]",
        )
        _extra_latency()

    @task(4)
    def search_orders(self):
        """GET /api/orders/search — safe keyword search."""
        self.client.get(
            "/api/orders/search?q=Casey",
            headers=HEADERS,
            name="GET /api/orders/search [golden]",
        )
        _extra_latency()

    @task(3)
    def get_receipt(self):
        """GET /api/orders/{id}/receipt — generate a receipt (safe)."""
        self.client.get(
            "/api/orders/1/receipt?format=txt",
            headers=HEADERS,
            name="GET /api/orders/{id}/receipt [golden]",
        )
        _extra_latency()

    @task(2)
    def admin_list_orders(self):
        """GET /api/admin/orders — broken-auth golden path (no creds needed)."""
        self.client.get(
            "/api/admin/orders",
            headers=HEADERS,
            name="GET /api/admin/orders [golden]",
        )
        _extra_latency()

    # ── Security failure scenarios ─────────────────────────────

    @task(2)
    def scenario_sqli(self):
        """SQL injection via search query parameter."""
        self.client.get(
            f"/api/orders/search?q={SQLI_PAYLOAD}",
            headers=HEADERS,
            name="GET /api/orders/search [sqli]",
        )

    @task(1)
    def scenario_cmd_injection_receipt(self):
        """Command injection via receipt format parameter."""
        self.client.get(
            f"/api/orders/1/receipt?format={CMD_INJECTION_RECEIPT}",
            headers=HEADERS,
            name="GET /api/orders/{id}/receipt [cmd-injection]",
        )

    @task(1)
    def scenario_cmd_injection_export(self):
        """Command injection via admin export filename."""
        self.client.post(
            "/api/admin/export",
            json={"filename": CMD_INJECTION_EXPORT},
            headers={**HEADERS, "Content-Type": "application/json"},
            name="POST /api/admin/export [cmd-injection]",
        )

    @task(2)
    def scenario_xss(self):
        """Stored XSS via order special instructions."""
        self.client.post(
            "/api/orders",
            json=_random_order_payload(special_instructions=XSS_PAYLOAD),
            headers=HEADERS,
            name="POST /api/orders [xss]",
        )

    @task(1)
    def scenario_sqli_union(self):
        """UNION-based SQL injection probing column count."""
        self.client.get(
            "/api/orders/search?q=' UNION SELECT NULL,NULL,NULL,NULL,NULL,NULL--",
            headers=HEADERS,
            name="GET /api/orders/search [sqli-union]",
        )


class BurstUser(HttpUser):
    """Periodic burst of high-frequency menu requests.

    Produces a visible spike in Datadog dashboards every ~5 minutes.
    """

    wait_time = constant_pacing(0.1)
    weight = 1

    _burst_active = False
    _next_burst = 0.0

    def on_start(self):
        self._next_burst = time.time() + random.uniform(60, 120)

    @task
    def burst_or_idle(self):
        now = time.time()
        if not self._burst_active and now >= self._next_burst:
            self._burst_active = True
            self._burst_end = now + 30
        if self._burst_active:
            if now >= self._burst_end:
                self._burst_active = False
                self._next_burst = now + random.uniform(240, 360)
                return
            self.client.get(
                "/api/menu",
                headers=HEADERS,
                name="GET /api/menu [burst]",
            )
        else:
            time.sleep(5)
