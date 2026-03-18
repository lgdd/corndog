from flask import Blueprint, jsonify, request
from app.services import order_service

orders_bp = Blueprint('orders', __name__, url_prefix='/api/orders')


@orders_bp.route('', methods=['POST'])
def create_order():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required'}), 400
    order = order_service.create_order(data)
    return jsonify(order), 201


@orders_bp.route('/search', methods=['GET'])
def search_orders():
    q = request.args.get('q', '')
    orders = order_service.search_orders(q)
    return jsonify(orders)


@orders_bp.route('/<int:order_id>', methods=['GET'])
def get_order(order_id):
    order = order_service.get_order(order_id)
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    return jsonify(order)


@orders_bp.route('/<int:order_id>/receipt', methods=['GET'])
def get_receipt(order_id):
    fmt = request.args.get('format', 'txt')
    result = order_service.generate_receipt(order_id, fmt)
    if not result:
        return jsonify({'error': 'Order not found'}), 404
    return jsonify(result)
