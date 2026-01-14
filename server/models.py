from google.cloud import ndb


class User(ndb.Model):
    """User model - identified by hashed phone number + app_id."""
    phone_hash = ndb.StringProperty(required=True)
    app_id = ndb.StringProperty(required=True)
    created_at = ndb.DateTimeProperty(auto_now_add=True)


class Session(ndb.Model):
    """Session model - stores auth tokens."""
    token = ndb.StringProperty(required=True)
    user_key = ndb.KeyProperty(kind=User, required=True)
    created_at = ndb.DateTimeProperty(auto_now_add=True)
