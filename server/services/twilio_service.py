from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

from creds import TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_VERIFY_SERVICE_SID


class TwilioError(Exception):
    """Custom exception for Twilio errors."""
    pass


# Test phone numbers that bypass Twilio
TEST_HAPPY_PATH = "+15305550000"
TEST_INVALID_PHONE = "+15305550001"
TEST_INVALID_CODE = "+15305550002"
TEST_MAX_ATTEMPTS = "+15305550003"
TEST_SERVICE_UNAVAILABLE = "+15305550004"

TEST_NUMBERS = {
    TEST_HAPPY_PATH,
    TEST_INVALID_PHONE,
    TEST_INVALID_CODE,
    TEST_MAX_ATTEMPTS,
    TEST_SERVICE_UNAVAILABLE,
}

TEST_VALID_CODE = "123456"


def get_twilio_client() -> Client:
    """Get configured Twilio client."""
    return Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)


def send_verification(phone_number: str) -> None:
    """Start a verification via Twilio Verify API.

    Raises TwilioError if the phone number is invalid or SMS cannot be sent.
    """
    if phone_number in TEST_NUMBERS:
        if phone_number == TEST_INVALID_PHONE:
            raise TwilioError("Failed to send verification: Invalid phone number")
        if phone_number == TEST_SERVICE_UNAVAILABLE:
            raise TwilioError("Failed to send verification: Service temporarily unavailable")
        return

    client = get_twilio_client()
    try:
        client.verify.v2.services(TWILIO_VERIFY_SERVICE_SID).verifications.create(
            to=phone_number,
            channel="sms",
        )
    except TwilioRestException as e:
        raise TwilioError(f"Failed to send verification: {e.msg}")


def check_verification(phone_number: str, code: str) -> bool:
    """Check a verification code via Twilio Verify API.

    Returns True if the code is valid, False otherwise.
    Raises TwilioError for unexpected errors.
    """
    if phone_number in TEST_NUMBERS:
        if phone_number == TEST_HAPPY_PATH:
            return code == TEST_VALID_CODE
        return False

    client = get_twilio_client()
    try:
        verification_check = client.verify.v2.services(
            TWILIO_VERIFY_SERVICE_SID
        ).verification_checks.create(
            to=phone_number,
            code=code,
        )
        return verification_check.status == "approved"
    except TwilioRestException as e:
        # 60200: Max verification attempts reached
        # 20404: Resource not found (no pending verification for this number)
        if e.code in (60200, 20404):
            return False
        raise TwilioError(f"Failed to verify code: {e.msg}")
