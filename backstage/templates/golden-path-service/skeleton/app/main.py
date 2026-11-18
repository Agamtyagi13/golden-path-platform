import os

from flask import Flask, jsonify


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/")
    def index():
        return jsonify(service="${{ values.name }}", owner="${{ values.ownerName }}", status="ok")

    @app.get("/healthz")
    def healthz():
        return jsonify(status="alive")

    @app.get("/readyz")
    def readyz():
        return jsonify(status="ready")

    return app


app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "${{ values.port }}")))
