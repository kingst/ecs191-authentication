import io
import uuid
from datetime import timedelta

from google.cloud import storage
from PIL import Image


BUCKET_NAME = "ecs191-login-bucket"
SIGNED_URL_EXPIRATION_MINUTES = 10

# Anthropic's limit is 5MB, but base64 encoding adds ~33% overhead
# So we limit raw image size to ~3.75MB to be safe
MAX_IMAGE_SIZE_BYTES = 3_750_000


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


def fetch_image(user_id: str, image_id: str) -> bytes | None:
    """
    Fetch an image from GCS.

    Args:
        user_id: The authenticated user's ID
        image_id: The image ID (UUID with .jpg extension)

    Returns:
        The image bytes, or None if the image doesn't exist
    """
    blob_path = f"images/{user_id}/{image_id}"

    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(blob_path)

    if not blob.exists():
        return None

    return blob.download_as_bytes()


# JPEG magic bytes: FF D8 FF
JPEG_MAGIC_BYTES = b'\xff\xd8\xff'


def is_valid_jpeg(data: bytes) -> bool:
    """Check if the data starts with JPEG magic bytes."""
    return data[:3] == JPEG_MAGIC_BYTES


def resize_image_if_needed(data: bytes) -> bytes:
    """
    Resize image if it exceeds the size limit for Anthropic API.

    Progressively reduces image dimensions until it fits within the size limit.

    Args:
        data: Original JPEG image bytes

    Returns:
        Image bytes that fit within MAX_IMAGE_SIZE_BYTES
    """
    if len(data) <= MAX_IMAGE_SIZE_BYTES:
        return data

    img = Image.open(io.BytesIO(data))

    # Convert to RGB if necessary (handles RGBA, etc.)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    quality = 85
    scale = 0.9

    while True:
        # Resize image
        new_width = int(img.width * scale)
        new_height = int(img.height * scale)
        resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # Save to bytes
        buffer = io.BytesIO()
        resized.save(buffer, format='JPEG', quality=quality)
        result = buffer.getvalue()

        if len(result) <= MAX_IMAGE_SIZE_BYTES:
            return result

        # Reduce scale for next iteration
        scale *= 0.8

        # Safety check - don't go too small
        if new_width < 200 or new_height < 200:
            # Last resort: reduce quality
            quality = max(50, quality - 10)
            scale = 1.0
            img = resized
