"""Scan history CRUD, scoped to the authenticated user."""
import json
import uuid
from datetime import datetime

from flask import Blueprint, request, jsonify, g

from db import db, Scan
from utils.jwt_utils import auth_required

scans_bp = Blueprint("scans", __name__)


def _scan_to_dict(scan: Scan) -> dict:
    return {
        "id": scan.uuid,
        "timestamp": scan.timestamp.isoformat() + "Z",
        "summary": {
            "score": scan.score,
            "status": scan.status,
            "confidence": scan.confidence,
            "confidence_label": scan.confidence_label,
        },
        "predictions": json.loads(scan.predictions_json or "[]"),
        "screening": (
            json.loads(scan.screening_json) if scan.screening_json else None
        ),
        "note": scan.note or "",
    }


@scans_bp.route("", methods=["POST"])
@auth_required
def create_scan():
    data = request.get_json(silent=True) or {}
    summary = data.get("summary") or {}
    predictions = data.get("predictions") or []
    screening = data.get("screening")
    note = (data.get("note") or "").strip()[:500]
    timestamp_str = data.get("timestamp")

    if timestamp_str:
        try:
            ts = datetime.fromisoformat(timestamp_str.replace("Z", ""))
        except ValueError:
            ts = datetime.utcnow()
    else:
        ts = datetime.utcnow()

    scan = Scan(
        uuid=str(uuid.uuid4()),
        user_id=g.current_user.id,
        timestamp=ts,
        score=int(summary.get("score") or 0),
        status=str(summary.get("status") or "Unknown"),
        confidence=float(summary.get("confidence") or 0.0),
        confidence_label=str(summary.get("confidence_label") or "Low"),
        note=note,
        predictions_json=json.dumps(predictions),
        screening_json=json.dumps(screening) if screening else None,
    )
    db.session.add(scan)
    db.session.commit()
    return jsonify(_scan_to_dict(scan)), 201


@scans_bp.route("", methods=["GET"])
@auth_required
def list_scans():
    try:
        limit = min(int(request.args.get("limit", 50)), 200)
    except ValueError:
        limit = 50

    scans = (
        Scan.query
        .filter_by(user_id=g.current_user.id)
        .order_by(Scan.timestamp.desc())
        .limit(limit)
        .all()
    )
    return jsonify({"scans": [_scan_to_dict(s) for s in scans]})


@scans_bp.route("/<scan_uuid>", methods=["GET"])
@auth_required
def get_scan(scan_uuid):
    scan = Scan.query.filter_by(
        uuid=scan_uuid, user_id=g.current_user.id
    ).first()
    if not scan:
        return jsonify({"error": "Scan not found"}), 404
    return jsonify(_scan_to_dict(scan))


@scans_bp.route("/<scan_uuid>", methods=["PATCH"])
@auth_required
def update_scan(scan_uuid):
    data = request.get_json(silent=True) or {}
    scan = Scan.query.filter_by(
        uuid=scan_uuid, user_id=g.current_user.id
    ).first()
    if not scan:
        return jsonify({"error": "Scan not found"}), 404

    if "note" in data:
        scan.note = (data["note"] or "").strip()[:500]
        db.session.commit()

    return jsonify(_scan_to_dict(scan))


@scans_bp.route("/<scan_uuid>", methods=["DELETE"])
@auth_required
def delete_scan(scan_uuid):
    scan = Scan.query.filter_by(
        uuid=scan_uuid, user_id=g.current_user.id
    ).first()
    if not scan:
        return jsonify({"error": "Scan not found"}), 404

    db.session.delete(scan)
    db.session.commit()
    return jsonify({"ok": True})


@scans_bp.route("", methods=["DELETE"])
@auth_required
def clear_scans():
    Scan.query.filter_by(user_id=g.current_user.id).delete()
    db.session.commit()
    return jsonify({"ok": True})