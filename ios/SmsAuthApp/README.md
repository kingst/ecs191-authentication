# SmsAuthApp (iOS example)

## Setting your app token

The SMS login endpoints require an app token (see [`server/API.md`](../../server/API.md#app-tokens)). The [test phone numbers](../../server/API.md#test-phone-numbers) work without one, so the app builds and runs with no setup. You only need a token to log in with a real phone number.

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig`
2. In `Config/Secrets.xcconfig`, replace `your_app_token_here` with your app token
3. Build and run

`Secrets.xcconfig` is listed in `.gitignore`, so your token stays out of git. Run `git status` before you commit; `Secrets.xcconfig` should never appear in it.

## How it works

`UserService.swift` reads `APP_TOKEN` from `Info.plist`. Xcode fills that in at build time from `Config/AppConfig.xcconfig`, which includes the gitignored `Config/Secrets.xcconfig`. To learn how the pieces fit together and how to set up the same pattern in your own app, see [`CREDENTIALS.md`](../../CREDENTIALS.md#ios-apps).
