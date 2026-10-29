# Twilio credentials
TWILIO_ACCOUNT_SID = "your_twilio_account_sid"
TWILIO_AUTH_TOKEN = "your_twilio_auth_token"
TWILIO_VERIFY_SERVICE_SID = "your_twilio_verify_service_sid"

# Salt for phone number hashing
# A good way to create this is:
#  dd if=/dev/urandom bs=64 count=1 | sha256sum
PHONE_HASH_SALT = "a large random number"

# Anthropic API key for food image analysis
ANTHROPIC_API_KEY = "your_anthropic_api_key"

# App tokens that clients must send as "app_token" in requests to
# /v1/send_sms_code and /v1/verify_code. Give each app its own token
# so you can revoke one by removing it from this list. An empty list
# rejects every request. A good way to create a token is:
#  python3 -c "import secrets; print(secrets.token_urlsafe(32))"
APP_TOKENS = [
    # "a long random token",
]
