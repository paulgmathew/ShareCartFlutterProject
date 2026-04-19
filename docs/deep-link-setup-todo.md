# Deep Link Setup — Android App Links & iOS Universal Links

Deep link handling is already wired in the Flutter app (via `app_links`, `main.dart` listener, and `AndroidManifest.xml` / `Info.plist`). The remaining work is on the **server and platform configuration** side.

---

## Android App Links

App Links let Android open the app directly (without a browser disambiguation dialog) when a user taps `https://sharecart.app/invite/<token>`.

### TODO

- [ ] **Host the Digital Asset Links file**
  - Create the file at: `https://sharecart.app/.well-known/assetlinks.json`
  - Content:
    ```json
    [
      {
        "relation": ["delegate_permission/common.handle_all_urls"],
        "target": {
          "namespace": "android_app",
          "package_name": "com.example.share_cart",
          "sha256_cert_fingerprints": [
            "<YOUR_RELEASE_SHA256_FINGERPRINT>"
          ]
        }
      }
    ]
    ```
  - Replace `com.example.share_cart` with the actual app package name from `android/app/build.gradle.kts` (`applicationId`).
  - Replace the fingerprint with the SHA-256 of your **release** signing certificate.
    - Get it with: `keytool -list -v -keystore <your-keystore>.jks`

- [ ] **Verify the file is reachable**
  - URL must return HTTP 200 with `Content-Type: application/json`
  - Test with: `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://sharecart.app&relation=delegate_permission/common.handle_all_urls`

- [ ] **Confirm `android:autoVerify="true"` is set**
  - Already done in `android/app/src/main/AndroidManifest.xml` on the invite `<intent-filter>`.

- [ ] **Test on a physical device**
  - Install a release/profile build.
  - Tap a `https://sharecart.app/invite/<token>` link — the app should open directly without the browser.

---

## iOS Universal Links

Universal Links let iOS open the app directly when a user taps `https://sharecart.app/invite/<token>`.

### TODO

- [ ] **Host the Apple App Site Association file**
  - Create the file at: `https://sharecart.app/.well-known/apple-app-site-association`
  - No `.json` extension — exact name required.
  - Content:
    ```json
    {
      "applinks": {
        "apps": [],
        "details": [
          {
            "appIDs": ["<TEAM_ID>.com.example.share_cart"],
            "components": [
              {
                "/": "/invite/*",
                "comment": "Matches all invite links"
              }
            ]
          }
        ]
      }
    }
    ```
  - Replace `<TEAM_ID>` with your Apple Developer Team ID (found in developer.apple.com → Membership).
  - Replace `com.example.share_cart` with the actual Bundle ID from `ios/Runner.xcodeproj`.

- [ ] **Verify the file is reachable**
  - URL must return HTTP 200 with `Content-Type: application/json`
  - No redirects allowed — Apple fetches it directly.
  - Test with Apple's validator: `https://app-site-association.cdn-apple.com/a/v1/sharecart.app`

- [ ] **Enable Associated Domains capability in Xcode**
  - Open `ios/Runner.xcodeproj` in Xcode.
  - Go to **Runner → Signing & Capabilities**.
  - Click **+ Capability** → add **Associated Domains**.
  - Add the entry: `applinks:sharecart.app`

- [ ] **Confirm `FlutterDeepLinkingEnabled` is set**
  - Already done in `ios/Runner/Info.plist`.

- [ ] **Test on a physical device**
  - Install via TestFlight or a development build.
  - Tap a `https://sharecart.app/invite/<token>` link in Safari or Messages — the app should open directly.

---

## Shared Checklist

- [ ] Decide on the final production domain (`sharecart.app` is used throughout — confirm this is correct).
- [ ] Ensure the backend generates invite URLs using `https://sharecart.app/invite/<token>` (check `POST /lists/{id}/invite-link` response).
- [ ] Confirm the web server at `sharecart.app` serves the `.well-known/` files with correct headers.
- [ ] After both files are live, do a full end-to-end test:
  1. Owner generates invite link on Android/iOS.
  2. Link is shared via native share sheet.
  3. Recipient (not logged in) taps link → app opens on `InvitePreviewScreen`.
  4. Recipient logs in → pending token is consumed → `InvitePreviewScreen` shown → joins list.
  5. Recipient (already logged in) taps link → app opens directly on `InvitePreviewScreen` → joins list.
