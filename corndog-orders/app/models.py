import json
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.Integer, primary_key=True)
    customer_name = db.Column(db.String(200), nullable=False)
    items = db.Column(db.Text, nullable=False)
    special_instructions = db.Column(db.Text)
    total_price = db.Column(db.Numeric(10, 2), nullable=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now())

    def to_dict(self):
        return {
            'id': self.id,
            'customerName': self.customer_name,
            'items': json.loads(self.items) if isinstance(self.items, str) else self.items,
            'specialInstructions': self.special_instructions,
            'totalPrice': float(self.total_price),
            'createdAt': self.created_at.isoformat() if self.created_at else None
        }
