import pytest
from unittest.mock import patch, MagicMock


def _raise_on_db_access(*args, **kwargs):
    """Raise an error if tests try to access the real database."""
    raise RuntimeError("Test attempted to access real database! Ensure Firestore is properly mocked.")


@pytest.fixture(autouse=True)
def block_real_database():
    """Block all real database access during tests.

    This fixture runs automatically for all tests and ensures that:
    1. ndb.Client() cannot create real connections
    2. Any attempt to use the real client raises an error
    """
    mock_client = MagicMock()
    mock_client.context.side_effect = _raise_on_db_access

    with patch("services.firestore_service.client", mock_client):
        yield
