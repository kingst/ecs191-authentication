from flask import Blueprint, request, jsonify

from services.firestore_service import get_session, get_user_by_key
from services.storage_service import generate_upload_url


food_api = Blueprint("food_api", __name__)


@food_api.route("/v1/food/upload_url", methods=["GET"])
def get_upload_url():
    """Get a signed URL for uploading a food image."""
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

    user_id = str(user.key.id())
    upload_url, image_id = generate_upload_url(user_id)

    return jsonify({
        "upload_url": upload_url,
        "image_id": image_id,
    })
