# STV MobileReader 1.3.3 — status of login/reader compatibility fix

Branch: `stv-capacitor-rebuild`. **This is the Capacitor reconstruction of MobileReader 1.3.3, not the independent SwiftUI / Native Reader application.**

## Fix applied
- Added `repair/stv-com-session.js`: pins the STV app's own networking domain selection to `https://sangtacviet.com`, so the account login request and session cookie do not change domains mid-session.
- Updated `repair/patch_app_delegate.py`: injects the session compatibility code before the STV page starts; keeps ordinary WKWebView cache behavior and first-party cookies.
- Preserves earlier `nativeclick.trigger` and CSS compatibility fixes required to open story details.

## Tests and evidence
- [Anonymous first-party login transport test](https://github.com/duongminhdong0607-bit/stvreader-ios-build/actions/runs/43845317364): passed. With **mock HTTP response** and **no real account** it sends POST containing expected field names to `sangtacviet.com`, no cross-domain login, JS error list empty. This test does NOT establish that a real account can authenticate.
- [Guest chapter comparison](https://github.com/duongminhdong0607-bit/stvreader-ios-build/actions/runs/43846128332): both ordinary browser and Capacitor iOS returned HTTP 200, but the response to `sajax=readchapter` contained **code "1", error "Platform unknown, please check your device."**, no chapter content. No credentials were used, and no text was exposed.
- [Updated Xcode build](https://github.com/duongminhdong0607-bit/stvreader-ios-build/actions/runs/43845359056): queued at last check; **no completed/verified new IPA** is available from this run.

## Not solved
1. Real login and synchronization with a user account: need real-device validation and server support; tests here do not have any user's credentials and never request those.
2. STV server rejects chapter data for this public/guest flow even outside iOS. Fix requires a supported chapter-read protocol and/or an STV developer-side change, not counterfeit keys or fabricated client IDs.
3. The original publisher's iOS plugin bundle and Xcode source are not included in the truncated public IPA.

## Privacy
No user passwords, token values, or cookies are recorded, printed, uploaded to GitHub, or sent to any non-STV service. The test logs only method, first-party host, and presence of expected form field names.

Build signed IPA on a macOS/Xcode runner or a local Mac. GitHub Actions output is **unsigned** and requires a legitimate iOS development signing method before installation.
