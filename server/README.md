You need to set up credentials, which are ignored by git (see
.gitignore):

  - Download a service key from app engine and move it to
   `google-auth.json` in the top level directory

  - Copy the `creds-empty.py` file to `creds.py`, which is also
    ignored by git. **Important:** Fill in your Twilio credentials and
    generate a random number for the salt.

    - e.g., dd if=/dev/urandom bs=64 count=1 | sha256sum

    - Then copy the random number you get from the previous command
      into the `creds.py` file

  - Fill in your account and project ID in the `deploy.sh` script

To test locally:

```bash
python3.13 -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python main.py
```

Then you should be able to access your service at
http://127.0.0.1:5001. **Important:** you will access your production
database with this setup when you are running your service locally, so
be careful.

To deploy:

```bash
./deploy.sh
```

After you deploy the deploy script will display the URL for your
production service. For our service it is:

  - https://ecs191-sms-authentication.uc.r.appspot.com

To run unit tests:

```bash
source venv/bin/activate
pytest
```

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

Notes:

- Validation errors (missing fields, invalid E.164 format) can be tested with any phone number
- Token-based errors (`Authorization header required`, `Invalid token`, `User not found`) are tested by manipulating the Authorization header, not by phone number
- The happy path code `123456` only works with the test number `+15305550000`