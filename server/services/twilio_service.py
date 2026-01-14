from twilio.rest import Client

from creds import TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_VERIFY_SERVICE_SID


def get_twilio_client() -> Client:
    """Get configured Twilio client."""
    return Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)


def send_verification(phone_number: str) -> None:
    """Start a verification via Twilio Verify API."""
    client = get_twilio_client()
    client.verify.v2.services(TWILIO_VERIFY_SERVICE_SID).verifications.create(
        to=phone_number,
        channel="sms",
    )


def check_verification(phone_number: str, code: str) -> bool:
    """Check a verification code via Twilio Verify API.

    Returns True if the code is valid, False otherwise.
    """
    client = get_twilio_client()
    verification_check = client.verify.v2.services(
        TWILIO_VERIFY_SERVICE_SID
    ).verification_checks.create(
        to=phone_number,
        code=code,
    )
    return verification_check.status == "approved"
