import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

from flask import Flask, jsonify
from flask_cors import CORS

from db import db, DB_PATH
from routes.auth import auth_bp
from routes.predict import predict_bp
from routes.chat import chat_bp
from routes.screen import screen_bp
from routes.scans import scans_bp
from utils.model_loader import load_all_models, get_health_status

app = Flask(__name__)
CORS(app)

# ── Database ─────────────────────────────────────────────────────
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{DB_PATH}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)

with app.app_context():
    db.create_all()
    print(f"[startup] Database ready at {DB_PATH}")

# ── ML models ────────────────────────────────────────────────────
print("=" * 55)
print("SuriStanya API — loading ML models...")
load_all_models()
print("Model loading complete.")
print("=" * 55)

# ── Blueprints ───────────────────────────────────────────────────
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(predict_bp, url_prefix="/predict")
app.register_blueprint(chat_bp, url_prefix="/chat")
app.register_blueprint(screen_bp, url_prefix="/screen")
app.register_blueprint(scans_bp, url_prefix="/scans")


@app.route("/")
def index():
    return jsonify({
        "status": "ok",
        "service": "Suristanya API",
        "version": "0.3.0",
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "models_loaded": get_health_status(),
    })


if __name__ == "__main__":
    # use_reloader=False to avoid loading 18 model files twice
    app.run(host="0.0.0.0", port=5000, debug=True, use_reloader=False)