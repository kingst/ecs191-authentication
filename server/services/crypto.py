import hashlib
import hmac

from creds import PHONE_HASH_SALT, APP_TOKENS


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


def is_valid_app_token(app_token: str) -> bool:
    """Check whether the app token is in the list of valid tokens in creds.py.

    Uses a constant-time comparison so response timing doesn't leak
    information about valid tokens.
    """
    if not isinstance(app_token, str):
        return False

    return any(
        hmac.compare_digest(app_token.encode("utf-8"), valid_token.encode("utf-8"))
        for valid_token in APP_TOKENS
    )
