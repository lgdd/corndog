import logging

from flask import Flask, request as flask_request
from flask_cors import CORS
from pythonjsonlogger import jsonlogger

from app.config import Config


def _configure_logging(app):
    handler = logging.StreamHandler()
    fmt = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s"
        " %(dd.trace_id)s %(dd.span_id)s"
        " %(dd.service)s %(dd.env)s %(dd.version)s",
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

    from app.routes.suggestions import suggestions_bp
    app.register_blueprint(suggestions_bp)

    @app.after_request
    def _log_request(response):
        app.logger.info(
            "%s %s %s",
            flask_request.method,
            flask_request.path,
            response.status_code,
        )
        return response

    return app
