import secrets

from google.cloud import ndb

from models import User, Session
from services.crypto import hash_phone_number


client = ndb.Client()


def get_or_create_user(phone_number: str, app_id: str) -> User:
    """Get existing user or create a new one for the given app."""
    phone_hash = hash_phone_number(phone_number)

    with client.context():
        query = User.query(
            User.phone_hash == phone_hash,
            User.app_id == app_id,
        )
        user = query.get()

        if user:
            return user

        user = User(phone_hash=phone_hash, app_id=app_id)
        user.put()
        return user


def create_session(user: User) -> str:
    """Create a session token for a user."""
    token = secrets.token_urlsafe(32)

    with client.context():
        session = Session(token=token, user_key=user.key)
        session.put()

    return token


def get_session(token: str) -> Session | None:
    """Get session by token. Returns None if not found."""
    with client.context():
        query = Session.query(Session.token == token)
        return query.get()


def get_user_by_key(user_key: ndb.Key) -> User | None:
    """Get user by key. Returns None if not found."""
    with client.context():
        return user_key.get()


def delete_user(user_key: ndb.Key) -> None:
    """Permanently delete a user and all of their sessions."""
    with client.context():
        session_keys = Session.query(Session.user_key == user_key).fetch(keys_only=True)

        # Delete everything in one transaction so a failure can't leave a
        # user without sessions or sessions without a user.
        ndb.transaction(lambda: ndb.delete_multi(session_keys + [user_key]))
