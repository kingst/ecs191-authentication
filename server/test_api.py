import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime

# Mock ndb.Client before importing app to prevent database connection at import time
with patch("google.cloud.ndb.Client"):
    from main import app
    from services.twilio_service import (
        TEST_HAPPY_PATH,
        TEST_INVALID_PHONE,
        TEST_INVALID_CODE,
        TEST_MAX_ATTEMPTS,
        TEST_SERVICE_UNAVAILABLE,
        TEST_VALID_CODE,
    )


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def mock_firestore():
    """Mock Firestore service functions."""
    with patch("api.auth.get_or_create_user") as mock_get_user, \
         patch("api.auth.create_session") as mock_create_session, \
         patch("api.auth.get_session") as mock_get_session, \
         patch("api.auth.get_user_by_key") as mock_get_user_by_key:

        mock_user = MagicMock()
        mock_user.key.id.return_value = "user_test123"
        mock_user.created_at = datetime(2025, 1, 13, 12, 0, 0)

        mock_get_user.return_value = mock_user
        mock_create_session.return_value = "test_token_abc123"

        mock_session = MagicMock()
        mock_session.user_key = mock_user.key
        mock_get_session.return_value = mock_session

        mock_get_user_by_key.return_value = mock_user

        yield {
            "get_or_create_user": mock_get_user,
            "create_session": mock_create_session,
            "get_session": mock_get_session,
            "get_user_by_key": mock_get_user_by_key,
            "user": mock_user,
        }


class TestSendSmsCode:
    """Tests for POST /v1/send_sms_code endpoint."""

    def test_missing_phone_number(self, client):
        """Should return 400 when phone_number is missing."""
        response = client.post("/v1/send_sms_code", json={"app_id": "test_app"})
        assert response.status_code == 400
        assert response.json["error"] == "phone_number is required"

    def test_missing_app_id(self, client):
        """Should return 400 when app_id is missing."""
        response = client.post("/v1/send_sms_code", json={"phone_number": "+14155551234"})
        assert response.status_code == 400
        assert response.json["error"] == "app_id is required"

    def test_invalid_phone_format(self, client):
        """Should return 400 for invalid E.164 format."""
        response = client.post("/v1/send_sms_code", json={
            "phone_number": "4155551234",
            "app_id": "test_app"
        })
        assert response.status_code == 400
        assert "Invalid phone number format" in response.json["error"]

    def test_happy_path_success(self, client):
        """Should return success for happy path test number."""
        response = client.post("/v1/send_sms_code", json={
            "phone_number": TEST_HAPPY_PATH,
            "app_id": "test_app"
        })
        assert response.status_code == 200
        assert response.json["success"] is True

    def test_invalid_phone_error(self, client):
        """Should return 400 for invalid phone test number."""
        response = client.post("/v1/send_sms_code", json={
            "phone_number": TEST_INVALID_PHONE,
            "app_id": "test_app"
        })
        assert response.status_code == 400
        assert "Invalid phone number" in response.json["error"]

    def test_service_unavailable_error(self, client):
        """Should return 400 for service unavailable test number."""
        response = client.post("/v1/send_sms_code", json={
            "phone_number": TEST_SERVICE_UNAVAILABLE,
            "app_id": "test_app"
        })
        assert response.status_code == 400
        assert "Service temporarily unavailable" in response.json["error"]

    def test_invalid_code_sends_successfully(self, client):
        """Invalid code test number should send successfully."""
        response = client.post("/v1/send_sms_code", json={
            "phone_number": TEST_INVALID_CODE,
            "app_id": "test_app"
        })
        assert response.status_code == 200
        assert response.json["success"] is True

    def test_max_attempts_sends_successfully(self, client):
        """Max attempts test number should send successfully."""
        response = client.post("/v1/send_sms_code", json={
            "phone_number": TEST_MAX_ATTEMPTS,
            "app_id": "test_app"
        })
        assert response.status_code == 200
        assert response.json["success"] is True


class TestVerifyCode:
    """Tests for POST /v1/verify_code endpoint."""

    def test_missing_fields(self, client):
        """Should return 400 when required fields are missing."""
        response = client.post("/v1/verify_code", json={"phone_number": "+14155551234"})
        assert response.status_code == 400
        assert "phone_number, app_id, and code are required" in response.json["error"]

    def test_happy_path_correct_code(self, client, mock_firestore):
        """Should return success with token for correct code."""
        response = client.post("/v1/verify_code", json={
            "phone_number": TEST_HAPPY_PATH,
            "app_id": "test_app",
            "code": TEST_VALID_CODE
        })
        assert response.status_code == 200
        assert response.json["success"] is True
        assert "token" in response.json
        assert "user_id" in response.json

    def test_happy_path_wrong_code(self, client, mock_firestore):
        """Should return 401 for wrong code on happy path number."""
        response = client.post("/v1/verify_code", json={
            "phone_number": TEST_HAPPY_PATH,
            "app_id": "test_app",
            "code": "000000"
        })
        assert response.status_code == 401
        assert "Invalid or expired code" in response.json["error"]

    def test_invalid_code_number_always_fails(self, client, mock_firestore):
        """Invalid code test number should always fail verification."""
        response = client.post("/v1/verify_code", json={
            "phone_number": TEST_INVALID_CODE,
            "app_id": "test_app",
            "code": TEST_VALID_CODE
        })
        assert response.status_code == 401
        assert "Invalid or expired code" in response.json["error"]

    def test_max_attempts_always_fails(self, client, mock_firestore):
        """Max attempts test number should always fail verification."""
        response = client.post("/v1/verify_code", json={
            "phone_number": TEST_MAX_ATTEMPTS,
            "app_id": "test_app",
            "code": TEST_VALID_CODE
        })
        assert response.status_code == 401
        assert "Invalid or expired code" in response.json["error"]


class TestGetUser:
    """Tests for GET /v1/user endpoint."""

    def test_missing_auth_header(self, client):
        """Should return 401 when Authorization header is missing."""
        response = client.get("/v1/user")
        assert response.status_code == 401
        assert "Authorization header required" in response.json["error"]

    def test_malformed_auth_header(self, client):
        """Should return 401 for malformed Authorization header."""
        response = client.get("/v1/user", headers={"Authorization": "InvalidFormat"})
        assert response.status_code == 401
        assert "Authorization header required" in response.json["error"]

    def test_invalid_token(self, client, mock_firestore):
        """Should return 401 for invalid token."""
        mock_firestore["get_session"].return_value = None
        response = client.get("/v1/user", headers={"Authorization": "Bearer invalid_token"})
        assert response.status_code == 401
        assert "Invalid token" in response.json["error"]

    def test_user_not_found(self, client, mock_firestore):
        """Should return 404 when user record is deleted."""
        mock_firestore["get_user_by_key"].return_value = None
        response = client.get("/v1/user", headers={"Authorization": "Bearer valid_token"})
        assert response.status_code == 404
        assert "User not found" in response.json["error"]

    def test_valid_token_returns_user(self, client, mock_firestore):
        """Should return user info for valid token."""
        response = client.get("/v1/user", headers={"Authorization": "Bearer valid_token"})
        assert response.status_code == 200
        assert "user_id" in response.json
        assert "created_at" in response.json
