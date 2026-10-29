# SMS Login API Documentation

Base URL: `https://ecs191-sms-authentication.uc.r.appspot.com` (production) or `http://localhost:5001` (local)

## Service Status

| Endpoint | Status |
|----------|--------|
| `POST /v1/send_sms_code` | Available (requires an `app_token`, except for [test phone numbers](#test-phone-numbers)) |
| `POST /v1/verify_code` | Available (requires an `app_token`, except for [test phone numbers](#test-phone-numbers)) |
| `GET /v1/user` | Available (requires a session token) |
| `GET /v1/food/upload_url` | **Temporarily disabled**, returns 404 |
| `GET /v1/food/analyze/{image_id}` | **Temporarily disabled**, returns 404 |

Disabled endpoints respond to every request with:

```json
{
  "error": "Not found"
}
```

---

## Authentication

The API uses two kinds of tokens:

| Token | Identifies | How you get it | How you send it |
|-------|------------|----------------|-----------------|
| App token | Your app | Issued by the course staff | `app_token` field in the JSON request body |
| Session token | A logged-in user | Returned by `/v1/verify_code` | `Authorization: Bearer <token>` header |

### App Tokens

`/v1/send_sms_code` and `/v1/verify_code` require an `app_token` field in the JSON request body, except for [test phone numbers](#test-phone-numbers). The server only accepts tokens on its list of valid app tokens, so ask the course staff for a token for your app.

```json
{
  "app_token": "your_app_token",
  "phone_number": "+14155551234",
  "app_id": "app_id_as42fasd432asgrt"
}
```

- Requests that use a [test phone number](#test-phone-numbers) don't need an app token, because test numbers never send a real SMS. You can build and test your login flow before you have a token.
- For every other phone number, the app token is checked before any other field. A request without a valid token returns 401 even if the other fields are also missing or invalid.
- Missing `app_token`: 401 `{"error": "app_token is required"}`
- Unknown `app_token`: 401 `{"error": "Invalid app_token"}`
- Treat your app token like a password. Don't commit it to a public repository or share it with other apps. Tokens that are leaked or abused will be revoked.
- For a standard way to keep your token out of git on iOS, see [`ios/SmsAuthApp/README.md`](../ios/SmsAuthApp/README.md#using-this-pattern-in-your-own-app).
- The app token is separate from `app_id`. `app_id` scopes user accounts (the same phone number gets a different `user_id` for each `app_id`), and the app token controls who can use the API.

### Session Tokens

After successful verification, the API returns a session token. Include this token in subsequent requests using the `Authorization` header:

```
Authorization: Bearer <token>
```

---

## Endpoints

### POST /v1/send_sms_code

Send a verification code to a phone number via SMS.

**Request**

```json
{
  "app_token": "your_app_token",
  "phone_number": "+14155551234",
  "app_id": "app_id_as42fasd432asgrt"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| app_token | string | Yes, except for test numbers | Your app token (see [App Tokens](#app-tokens)) |
| phone_number | string | Yes | Phone number in E.164 format (e.g., +14155551234) |
| app_id | string | Yes | the app ID for this verification |

**Response**

Success (200):
```json
{
  "success": true
}
```

Errors:

| Status | Response | Description |
|--------|----------|-------------|
| 401 | `{"error": "app_token is required"}` | Missing app_token field |
| 401 | `{"error": "Invalid app_token"}` | app_token is not a valid app token |
| 400 | `{"error": "phone_number is required"}` | Missing phone_number field |
| 400 | `{"error": "app_id is required"}` | Missing app_id field |
| 400 | `{"error": "Invalid phone number format. Use E.164 format (e.g., +14155551234)"}` | Phone number not in E.164 format |

**Example**

```bash
curl -X POST http://localhost:5001/v1/send_sms_code \
  -H "Content-Type: application/json" \
  -d '{"app_token": "your_app_token", "phone_number": "+14155551234", "app_id": "app_id_aw24asdfq234"}'
```

---

### POST /v1/verify_code

Verify the SMS code and receive a session token.

**Request**

```json
{
  "app_token": "your_app_token",
  "phone_number": "+14155551234",
  "app_id": "app_id_wqerasde432ads",
  "code": "123456"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| app_token | string | Yes, except for test numbers | Your app token (see [App Tokens](#app-tokens)) |
| phone_number | string | Yes | Phone number that received the code |
| app_id | string | Yes | The app ID for this user |
| code | string | Yes | 6-digit verification code from SMS |

**Response**

Success (200):
```json
{
  "success": true,
  "token": "abc123...",
  "user_id": "user_aweragasder"
}
```

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | Always true on success |
| token | string | Session token for authenticating future requests |
| user_id | string | A unique identifier for this user |

Errors:

| Status | Response | Description |
|--------|----------|-------------|
| 401 | `{"error": "app_token is required"}` | Missing app_token field |
| 401 | `{"error": "Invalid app_token"}` | app_token is not a valid app token |
| 400 | `{"error": "phone_number, app_id, and code are required"}` | Missing required fields |
| 401 | `{"error": "Invalid or expired code"}` | Code doesn't match or has expired (5 min TTL) |

**Example**

```bash
curl -X POST http://localhost:5001/v1/verify_code \
  -H "Content-Type: application/json" \
  -d '{"app_token": "your_app_token", "phone_number": "+14155551234", "code": "123456", "app_id": "app_id_asd423asdf"}'
```

---

### GET /v1/user

Get the authenticated user's information. This endpoint doesn't take an `app_token`; the session token in the `Authorization` header is enough. Use it to check whether a saved session token is still valid.

**Headers**

| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token from verify_code response |

**Response**

Success (200):
```json
{
  "user_id": "user_id_asd234asdf",
  "created_at": "2025-01-13T12:00:00+00:00"
}
```

| Field | Type | Description |
|-------|------|-------------|
| user_id | string | User's unique identifier |
| created_at | string | ISO 8601 timestamp of account creation |

Errors:

| Status | Response | Description |
|--------|----------|-------------|
| 401 | `{"error": "Authorization header required"}` | Missing or malformed Authorization header |
| 401 | `{"error": "Invalid token"}` | Token not found or expired |
| 404 | `{"error": "User not found"}` | User record was deleted |

**Example**

```bash
curl http://localhost:5001/v1/user \
  -H "Authorization: Bearer abc123..."
```

---

## Phone Number Format

All phone numbers must be in [E.164 format](https://en.wikipedia.org/wiki/E.164):

- Starts with `+`
- Country code (1-3 digits)
- Subscriber number
- No spaces, dashes, or parentheses

**Examples:**
- US: `+14155551234`
- UK: `+442071234567`
- Germany: `+4930123456`

---

## Test Phone Numbers

The server recognizes several phone numbers that bypass Twilio and return predictable responses, similar to Stripe's test credit card numbers. These numbers never send a real SMS, so they **don't need an `app_token`**.

| Phone Number | Scenario | Behavior |
|--------------|----------|----------|
| +15305550000 | Happy path | Sends successfully; use code `123456` to verify |
| +15305550001 | Invalid phone number | Returns 400: `Failed to send verification: Invalid phone number` |
| +15305550002 | Invalid code | Sends successfully; any code returns 401: `Invalid or expired code` |
| +15305550003 | Max attempts reached | Sends successfully; code check returns 401: `Invalid or expired code` (simulates too many failed attempts) |
| +15305550004 | Service unavailable | Returns 400: `Failed to send verification: Service temporarily unavailable` |

**Example** (no app token needed)

```bash
curl -X POST https://ecs191-sms-authentication.uc.r.appspot.com/v1/send_sms_code \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+15305550000", "app_id": "app_id_aw24asdfq234"}'

curl -X POST https://ecs191-sms-authentication.uc.r.appspot.com/v1/verify_code \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+15305550000", "code": "123456", "app_id": "app_id_aw24asdfq234"}'
```

---

## Error Response Format

All errors return a JSON object with an `error` field:

```json
{
  "error": "Description of what went wrong"
}
```

---

## Rate Limits

Currently no rate limits are enforced. For production use, consider implementing rate limiting on the `/v1/send_sms_code` endpoint to prevent SMS abuse.

---

## Food Analysis APIs

> **Temporarily disabled.** Both food endpoints currently return 404 `{"error": "Not found"}` for every request. The documentation below describes their behavior when they are enabled.

These endpoints allow authenticated users to upload food images and receive nutritional estimates.

### GET /v1/food/upload_url

Get a signed URL for uploading a food image to Google Cloud Storage.

**Headers**

| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token from verify_code response |

**Response**

Success (200):
```json
{
  "upload_url": "https://storage.googleapis.com/ecs191-login-bucket/...",
  "image_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg"
}
```

| Field | Type | Description |
|-------|------|-------------|
| upload_url | string | Signed URL for PUT request to upload image (valid for 10 minutes) |
| image_id | string | URL-safe unique identifier for the image (UUID format with .jpg extension) |

Errors:

| Status | Response | Description |
|--------|----------|-------------|
| 401 | `{"error": "Authorization header required"}` | Missing or malformed Authorization header |
| 401 | `{"error": "Invalid token"}` | Token not found or expired |

**Example**

```bash
curl http://localhost:5001/v1/food/upload_url \
  -H "Authorization: Bearer abc123..."
```

**Uploading the Image**

After receiving the signed URL, upload your JPEG image using a PUT request:

```bash
curl -X PUT \
  -H "Content-Type: image/jpeg" \
  --data-binary @food_photo.jpg \
  "https://storage.googleapis.com/ecs191-login-bucket/..."
```

---

### GET /v1/food/analyze/{image_id}

Analyze a previously uploaded food image and return nutritional estimates.

**Headers**

| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token from verify_code response |

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| image_id | string | The URL-safe image ID returned from the upload_url endpoint |

**Response**

Success (200):
```json
{
  "calories": 650,
  "carbohydrates_grams": 45,
  "protein_grams": 35,
  "description": "Burger and fries",
  "image_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg",
  "confidence": "high"
}
```

| Field | Type | Description |
|-------|------|-------------|
| calories | integer | Estimated calories in the meal |
| carbohydrates_grams | integer | Estimated carbohydrates in grams |
| protein_grams | integer | Estimated protein in grams |
| description | string | Brief description of the food identified |
| image_id | string | The image ID that was analyzed |
| confidence | string | Confidence level in the estimate: "high", "medium", or "low" |

Errors:

| Status | Response | Description |
|--------|----------|-------------|
| 401 | `{"error": "Authorization header required"}` | Missing or malformed Authorization header |
| 401 | `{"error": "Invalid token"}` | Token not found or expired |
| 404 | `{"error": "Image not found"}` | Image ID does not exist in storage |
| 400 | `{"error": "Invalid image format"}` | Uploaded file is not a valid JPEG image |
| 400 | `{"error": "Could not analyze image: <reason>"}` | Image does not contain food, is too blurry, or food is too obscured |
| 502 | `{"error": "Analysis service error: <details>"}` | Anthropic API returned an error |

**Example**

```bash
curl "http://localhost:5001/v1/food/analyze/a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg" \
  -H "Authorization: Bearer abc123..."
```
