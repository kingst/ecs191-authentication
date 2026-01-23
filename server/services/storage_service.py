import uuid
from datetime import timedelta

from google.cloud import storage


BUCKET_NAME = "ecs191-login-bucket"
SIGNED_URL_EXPIRATION_MINUTES = 10


def generate_upload_url(user_id: str) -> tuple[str, str]:
    """
    Generate a signed URL for uploading an image to GCS.

    Args:
        user_id: The authenticated user's ID

    Returns:
        A tuple of (signed_url, image_id) where:
        - signed_url: URL the client can use to PUT the image
        - image_id: URL-safe identifier for the image (UUID with .jpg extension)
    """
    image_id = f"{uuid.uuid4()}.jpg"
    blob_path = f"images/{user_id}/{image_id}"

    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(blob_path)

    signed_url = blob.generate_signed_url(
        version="v4",
        expiration=timedelta(minutes=SIGNED_URL_EXPIRATION_MINUTES),
        method="PUT",
        content_type="image/jpeg",
    )

    return signed_url, image_id
