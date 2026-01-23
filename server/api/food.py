from flask import Blueprint, request, jsonify

from services.firestore_service import get_session, get_user_by_key
from services.storage_service import generate_upload_url, fetch_image, is_valid_jpeg, resize_image_if_needed
from services.anthropic_service import analyze_food_image, AnthropicError


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


@food_api.route("/v1/food/analyze/<image_id>", methods=["GET"])
def analyze_image(image_id):
    """Analyze a food image and return nutritional estimates."""
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

    # Fetch the image from GCS
    image_data = fetch_image(user_id, image_id)

    if image_data is None:
        return jsonify({"error": "Image not found"}), 404

    # Validate JPEG format
    if not is_valid_jpeg(image_data):
        return jsonify({"error": "Invalid image format"}), 400

    # Resize if needed
    image_data = resize_image_if_needed(image_data)

    # Analyze the image
    try:
        result = analyze_food_image(image_data)
    except AnthropicError as e:
        return jsonify({"error": f"Analysis service error: {e}"}), 502

    # Check if the image contains food
    if not result.is_food:
        return jsonify({"error": f"Could not analyze image: {result.description}"}), 400

    return jsonify({
        "calories": result.calories,
        "carbohydrates_grams": result.carbohydrates_grams,
        "protein_grams": result.protein_grams,
        "description": result.description,
        "confidence": result.confidence,
        "image_id": image_id,
    })
