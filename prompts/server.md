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
verification directly. We need to catch errors returned from the
Twilio API due to invalid phone numbers, incorrect codes, or any other
errors that Twilio might throw.

## Testing phone numbers

To help people test, the server recognizes several phone numbers that
bypass Twilio and return predictable responses. This is similar to
Stripe's test credit card numbers.

All test numbers use the format: `+1530555XXXX`

| Phone Number | Scenario | Behavior |
|--------------|----------|----------|
| +15305550000 | Happy path | Sends successfully; use code `123456` to verify |
| +15305550001 | Invalid phone number | Returns 400: `Failed to send verification: Invalid phone number` |
| +15305550002 | Invalid code | Sends successfully; any code returns 401: `Invalid or expired code` |
| +15305550003 | Max attempts reached | Sends successfully; code check returns 401: `Invalid or expired code` (simulates too many failed attempts) |
| +15305550004 | Service unavailable | Returns 400: `Failed to send verification: Service temporarily unavailable` |

### Notes

- Validation errors (missing fields, invalid E.164 format) can be tested with any phone number
- Token-based errors (`Authorization header required`, `Invalid token`, `User not found`) are tested by manipulating the Authorization header, not by phone number
- The happy path code `123456` only works with the test number `+15305550000`
