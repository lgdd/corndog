import logging
import os

from flask import Flask
from flask_cors import CORS
from pythonjsonlogger import jsonlogger

from app.config import Config
from app.models import db


def _configure_logging(app):
    handler = logging.StreamHandler()
    fmt = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s",
        rename_fields={"asctime": "timestamp", "levelname": "level"},
    )
    handler.setFormatter(fmt)

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(logging.INFO)
    app.logger.handlers = root.handlers


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    _configure_logging(app)

    CORS(app)
    db.init_app(app)

    from app.routes.orders import orders_bp
    app.register_blueprint(orders_bp)

    return app
