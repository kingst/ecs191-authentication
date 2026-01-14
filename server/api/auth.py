import re
from flask import Blueprint, request, jsonify

from services.firestore_service import (
    get_or_create_user,
    create_session,
    get_session,
    get_user_by_key,
)
from services.twilio_service import send_verification, check_verification, TwilioError


auth_api = Blueprint("auth_api", __name__)

E164_PATTERN = re.compile(r"^\+[1-9]\d{1,14}$")


def validate_phone_number(phone_number: str) -> bool:
    """Validate phone number is in E.164 format."""
    return bool(E164_PATTERN.match(phone_number))


@auth_api.route("/v1/send_sms_code", methods=["POST"])
def send_sms_code():
    """Send a verification code to the given phone number."""
    data = request.get_json()

    if not data or "phone_number" not in data:
        return jsonify({"error": "phone_number is required"}), 400

    if "app_id" not in data:
        return jsonify({"error": "app_id is required"}), 400

    phone_number = data["phone_number"]

    if not validate_phone_number(phone_number):
        return jsonify({"error": "Invalid phone number format. Use E.164 format (e.g., +14155551234)"}), 400

    try:
        send_verification(phone_number)
    except TwilioError as e:
        return jsonify({"error": str(e)}), 400

    return jsonify({"success": True})


@auth_api.route("/v1/verify_code", methods=["POST"])
def verify_code_endpoint():
    """Verify the code and return a session token."""
    data = request.get_json()

    if not data or "phone_number" not in data or "app_id" not in data or "code" not in data:
        return jsonify({"error": "phone_number, app_id, and code are required"}), 400

    phone_number = data["phone_number"]
    app_id = data["app_id"]
    code = data["code"]

    try:
        if not check_verification(phone_number, code):
            return jsonify({"error": "Invalid or expired code"}), 401
    except TwilioError as e:
        return jsonify({"error": str(e)}), 400

    user = get_or_create_user(phone_number, app_id)
    token = create_session(user)

    return jsonify({"success": True, "token": token, "user_id": str(user.key.id())})


@auth_api.route("/v1/user", methods=["GET"])
def get_user():
    """Get the current user's information."""
    auth_header = request.headers.get("Authorization")

    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Authorization header required"}), 401

    token = auth_header[7:]  # Remove "Bearer " prefix
    session = get_session(token)

    if not session:
        return jsonify({"error": "Invalid token"}), 401

    user = get_user_by_key(session.user_key)

    if not user:
        return jsonify({"error": "User not found"}), 404

    return jsonify({
        "user_id": str(user.key.id()),
        "created_at": user.created_at.isoformat() if user.created_at else None,
    })
