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
