import hashlib

from creds import PHONE_HASH_SALT


def hash_phone_number(phone_number: str) -> str:
    """Hash a phone number using PBKDF2 with the configured salt.

    Returns a hex-encoded hash that can be used as a database key.
    """
    return hashlib.pbkdf2_hmac(
        "sha256",
        phone_number.encode("utf-8"),
        PHONE_HASH_SALT.encode("utf-8"),
        iterations=100000,
    ).hex()
