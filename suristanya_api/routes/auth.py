from flask import Blueprint, request, jsonify
import uuid

auth_bp = Blueprint("auth", __name__)

_users = {}


@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not name or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400

    if email in _users:
        return jsonify({"error": "Email already registered"}), 409

    user_id = str(uuid.uuid4())
    _users[email] = {
        "id": user_id,
        "name": name,
        "email": email,
        "password": password,
    }

    return jsonify({
        "token": f"mock-token-{user_id}",
        "user": {"id": user_id, "name": name, "email": email},
    }), 201


@auth_bp.route("/signin", methods=["POST"])
def signin():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400

    user = _users.get(email)
    if not user or user["password"] != password:
        return jsonify({"error": "Invalid credentials"}), 401

    return jsonify({
        "token": f"mock-token-{user['id']}",
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
        },
    })


@auth_bp.route("/forgot", methods=["POST"])
def forgot():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()

    if not email:
        return jsonify({"error": "Email required"}), 400

    return jsonify({
        "message": "If that email exists, a reset link has been sent.",
        "email": email,
    })


@auth_bp.route("/me", methods=["GET"])
def me():
    return jsonify({"user": None, "note": "Auth not enforced yet"})