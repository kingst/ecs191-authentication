# SmsAuthApp (iOS example)

## Setting your app token

The SMS login endpoints require an app token (see [`server/API.md`](../../server/API.md#app-tokens)). The [test phone numbers](../../server/API.md#test-phone-numbers) work without one, so the app builds and runs with no setup. You only need a token to log in with a real phone number.

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig`
2. In `Config/Secrets.xcconfig`, replace `your_app_token_here` with your app token
3. Build and run

`Secrets.xcconfig` is listed in `.gitignore`, so your token stays out of git. Run `git status` before you commit; `Secrets.xcconfig` should never appear in it.

## How it works

The token flows from a gitignored file into the app at build time:

```
Config/Secrets.xcconfig        APP_TOKEN = abc123...        (gitignored)
        ↓ #include?
Config/AppConfig.xcconfig      the target's base configuration (committed)
        ↓ build setting
Info.plist                     APP_TOKEN = $(APP_TOKEN)
        ↓ at runtime
UserService.swift              Bundle.main.object(forInfoDictionaryKey: "APP_TOKEN")
```

The `?` in `#include?` makes the include optional, so a fresh clone without `Secrets.xcconfig` still builds. The token is just empty, and the app leaves `app_token` out of its requests.

## Using this pattern in your own app

1. **Ignore the secrets file first.** Add this line to your `.gitignore` *before* you create the file:

   ```
   Secrets.xcconfig
   ```

2. **Create the config files** in a `Config` folder next to your `.xcodeproj`, **not** inside your app's source folder. New Xcode projects use synchronized folders, which copy every file in the app folder into the app bundle, including `.xcconfig` files.

   `Config/AppConfig.xcconfig` (commit this):

   ```
   APP_TOKEN =

   #include? "Secrets.xcconfig"
   ```

   `Config/Secrets.xcconfig` (never commit this):

   ```
   APP_TOKEN = your_app_token
   ```

   It's also helpful to commit a `Config/Secrets.example.xcconfig` with a placeholder value so others know what to create.

3. **Add `AppConfig.xcconfig` to your project.** Use File → Add Files to "YourApp"…, select `Config/AppConfig.xcconfig`, and make sure your app target is **unchecked** under Targets. The file only needs to be in the project, not built into the app.

4. **Make it the base configuration.** Select your project (the blue icon) → the **project** under PROJECT → **Info** tab → **Configurations**. Expand Debug and Release, and set your app target's configuration file to `AppConfig` in both.

5. **Expose the setting in Info.plist.** Select your app target → **Info** tab → Custom iOS Target Properties, and add a row:

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

   Then include it as `app_token` in the JSON body of `/v1/send_sms_code` and `/v1/verify_code`.

## Things to know

- **If you commit a token by accident, deleting it in a later commit doesn't help.** It's still in your git history. Ask for a new token and have the old one revoked.
- **This keeps your token off GitHub, not secret from people who have your app.** Anything you ship inside an app can be extracted from it. That's why each app gets its own token that can be revoked if it's abused.
- **xcconfig files treat `//` as the start of a comment,** so a value can't contain `//`. App tokens never do, but URLs do.
