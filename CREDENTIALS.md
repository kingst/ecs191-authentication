# Keeping Secrets Out of GitHub

API keys, auth tokens, passwords, and salts let whoever has them act as you. With them, someone can send texts on your Twilio account, run up charges on your Anthropic account, or read your database. Automated scanners watch public GitHub repositories for leaked keys, so treat any secret pushed to a public repo as stolen.

This guide shows how this repo keeps secrets out of git in both the Python server and the iOS app, so you can use the same approach in your own projects.

## The pattern

Every platform uses the same three pieces:

| Piece | Committed to git? | Server example | iOS example |
|-------|-------------------|----------------|-------------|
| A secrets file with the real values | **No**, it's in `.gitignore` | `server/creds.py` | `ios/SmsAuthApp/Config/Secrets.xcconfig` |
| A template with placeholder values | Yes | `server/creds-empty.py` | `ios/SmsAuthApp/Config/Secrets.example.xcconfig` |
| Code that reads the values | Yes | `from creds import ...` | `Bundle.main.object(forInfoDictionaryKey:)` |

Anyone who clones your repo copies the template, fills in their own values, and everything works. The real values never touch git.

**Add the secrets file to `.gitignore` before you create it.** If the file exists first, it's easy to commit it by accident with `git add .`.

## Python servers on App Engine

### Set it up

1. **Ignore the secrets files.** Add them to the `.gitignore` in your server directory:

   ```
   creds.py
   google-auth.json
   ```

   `google-auth.json` is your Google Cloud service account key, and it's a secret too.

2. **Commit a template** named `creds-empty.py` with placeholder values. This repo's version is [`server/creds-empty.py`](server/creds-empty.py):

   ```python
   TWILIO_ACCOUNT_SID = "your_twilio_account_sid"
   TWILIO_AUTH_TOKEN = "your_twilio_auth_token"
   ANTHROPIC_API_KEY = "your_anthropic_api_key"
   ```

3. **Create your real secrets file** from the template and fill in your values:

   ```bash
   cp creds-empty.py creds.py
   ```

4. **Import secrets where you need them:**

   ```python
   from creds import ANTHROPIC_API_KEY
   ```

   In this repo, only the modules in `server/services/` import from `creds`, so each secret is used in one place.

Don't put secrets in `app.yaml` (for example under `env_variables`), because `app.yaml` is committed.

### Deploying: `.gitignore` vs. `.gcloudignore`

`.gitignore` controls what goes to GitHub. `.gcloudignore` controls what `gcloud app deploy` uploads to App Engine. Your server needs `creds.py` when it runs, so `creds.py` must be **ignored by git but uploaded by gcloud**.

- **Check `.gcloudignore` for `#!include:.gitignore`.** That line makes gcloud skip everything in `.gitignore`, including `creds.py`. Your deployed server then crashes on startup with `ModuleNotFoundError: No module named 'creds'`. Remove the line.
- **Check the upload list before you deploy.** Run this in your server directory; `creds.py` should be in the list:

  ```bash
  gcloud meta list-files-for-upload
  ```

- **Make your deploy script check too.** This repo's [`server/deploy.sh`](server/deploy.sh) won't deploy if `creds.py` or `google-auth.json` is missing.

For larger production apps, [Google Secret Manager](https://cloud.google.com/secret-manager) keeps secrets out of your code and your uploads entirely. It's more setup than this class needs.

## iOS apps

### What belongs in an app

Anyone who downloads your app can extract anything you ship inside it. Keeping a value out of GitHub is not the same as keeping it secret.

- **OK in an app:** low-privilege values that can be revoked, like your app token for the SMS login service. If it leaks, it gets revoked and you get a new one.
- **Never in an app:** keys that can spend money or reach data directly, like Twilio credentials, Anthropic API keys, or service account keys. Keep those on your server and have your app call your server. That's why this repo's iOS app never talks to Twilio or Anthropic directly.

### How it works

The value travels from a gitignored file into the app at build time:

```
Config/Secrets.xcconfig        APP_TOKEN = abc123...           (gitignored)
        ↓ #include?
Config/AppConfig.xcconfig      the target's base configuration (committed)
        ↓ build setting
Info.plist                     APP_TOKEN = $(APP_TOKEN)
        ↓ at runtime
Swift code                     Bundle.main.object(forInfoDictionaryKey: "APP_TOKEN")
```

### Set it up

1. **Ignore the secrets file.** Add this line to your `.gitignore` *before* you create the file:

   ```
   Secrets.xcconfig
   ```

2. **Create the config files** in a `Config` folder next to your `.xcodeproj`, **not** inside your app's source folder (see the first item under [Gotchas](#gotchas)).

   `Config/AppConfig.xcconfig` (commit this):

   ```
   APP_TOKEN =

   #include? "Secrets.xcconfig"
   ```

   `Config/Secrets.xcconfig` (never commit this):

   ```
   APP_TOKEN = your_app_token
   ```

   Also commit a `Config/Secrets.example.xcconfig` with a placeholder value, so others know what to create.

3. **Add `AppConfig.xcconfig` to your project.** Use File → Add Files to "YourApp"…, select `Config/AppConfig.xcconfig`, and make sure your app target is **unchecked** under Targets. The file needs to be in the project, but not built into the app.

4. **Make it the base configuration.** Select your project (the blue icon), then the **project** under PROJECT, then the **Info** tab → **Configurations**. Expand Debug and Release, and set your app target's configuration file to `AppConfig` in both.

5. **Add the value to Info.plist.** Select your app target → **Info** tab → Custom iOS Target Properties, and add a row:

   | Key | Type | Value |
   |-----|------|-------|
   | `APP_TOKEN` | String | `$(APP_TOKEN)` |

6. **Read it in Swift:**

   ```swift
   private static let appToken: String? = {
       let token = Bundle.main.object(forInfoDictionaryKey: "APP_TOKEN") as? String
       return token?.isEmpty == false ? token : nil
   }()
   ```

For a working example, see [`ios/SmsAuthApp`](ios/SmsAuthApp/README.md). Its `UserService.swift` sends the token as `app_token`.

### Gotchas

- **Keep `Config/` out of your app's source folder.** New Xcode projects use synchronized folders, which copy every file in the app folder into the app bundle, including `.xcconfig` files.
- **The `?` in `#include?` matters.** It makes the include optional, so a fresh clone without `Secrets.xcconfig` still builds. The value is just empty, so your code should handle that.
- **xcconfig files treat `//` as the start of a comment,** so a value can't contain `//`. Tokens and keys never do, but URLs do.
- **If the app doesn't pick up a changed value,** use Product → Clean Build Folder and build again.

## Before you commit

Run `git status` and read the list; your secrets files should never be in it. To check that a specific file is ignored:

```bash
git check-ignore -v server/creds.py
```

This prints the `.gitignore` rule that ignores the file. If it prints nothing, the file is **not** ignored.

## If you commit a secret by accident

- **If you haven't pushed yet,** undo the commit with `git reset HEAD~1`. Your changes stay in your working directory. Add the file to `.gitignore`, then commit again.
- **If you already pushed,** treat the secret as stolen. Revoke it and create a new one in the provider's console (Twilio, Anthropic, or Google Cloud). For an app token, ask the course staff for a new one. Deleting the file in a new commit doesn't help, because the secret is still in your git history.

## Generating random secrets

For salts and tokens you create yourself:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```
