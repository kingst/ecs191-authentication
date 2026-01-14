# Server

Our server is a Google App Engine Python server, the source code is in
the @server directory. It will expose three API calls, which you can
find documented in @server/API.md

To store secrets, we will have a `creds.py` file that has variables
for the Twilio secrets and for a `salt` parameter. In our store we
don't store phone numbers directly and instead run them through a
password derivation function, using the `salt` to help provide
entropy.

For a database, we'll use Firestore in Datastore mode. I really don't
like the whole idea of a collection, I'd like to use proper models.

With Twilio, we will use their Verify API instead of sending SMS for
verification directly.

