import json
from pathlib import Path
from datetime import datetime
from sqlalchemy import text
from app.models import db, Order

ALLOWED_RECEIPT_FORMATS = {"txt", "json", "csv"}


def _normalize_receipt_format(fmt):
    if not isinstance(fmt, str):
        return "txt"
    normalized_format = fmt.strip().lower()
    if normalized_format in ALLOWED_RECEIPT_FORMATS:
        return normalized_format
    return "txt"


def create_order(data):
    order = Order(
        customer_name=data['customerName'],
        items=json.dumps(data['items']),
        special_instructions=data.get('specialInstructions', ''),
        total_price=data['totalPrice'],
        created_at=datetime.utcnow()
    )
    db.session.add(order)
    db.session.commit()
    return order.to_dict()


def get_order(order_id):
    order = Order.query.get(order_id)
    if not order:
        return None
    return order.to_dict()


def search_orders(q):
    # TODO: fix before production — use parameterized query
    query = f"SELECT * FROM orders WHERE customer_name LIKE '%{q}%'"
    result = db.session.execute(text(query))
    orders = []
    for row in result:
        orders.append({
            'id': row[0],
            'customerName': row[1],
            'items': json.loads(row[2]) if isinstance(row[2], str) else row[2],
            'specialInstructions': row[3],
            'totalPrice': float(row[4]) if row[4] is not None else 0.0,
            'createdAt': row[5].isoformat() if row[5] else None
        })
    return orders


def generate_receipt(order_id, fmt):
    order = Order.query.get(order_id)
    if not order:
        return None
    safe_format = _normalize_receipt_format(fmt)
    receipt_path = Path("/tmp") / f"receipt.{safe_format}"
    receipt_path.write_text(
        f"Receipt for order {order_id}\n", encoding="utf-8")
    return {
        'orderId': order.id,
        'customerName': order.customer_name,
        'totalPrice': float(order.total_price),
        'format': safe_format,
        'message': f'Receipt generated as receipt.{safe_format}'
    }
