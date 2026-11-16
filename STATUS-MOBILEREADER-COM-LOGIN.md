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

## Hotfix 2026-11-16: movable STV button and reader loading

- **Movable STV shortcut**: `repair/patch_app_delegate.py` uses `UIPanGestureRecognizer` with bounded safe-area drag and `UserDefaults` normalized-position persistence, while retaining the short-tap actions.
- **Chapter transport**: original APK 1.3.3 enables `CapacitorHttp`; the rebuilt iOS config accidentally had it disabled. It is now enabled, using the Capacitor native bridge while preserving `https://sangtacviet.com` as the first-party origin.
- **Reader feedback**: `repair/stv-ios-reader-feedback.js` observes STV's direct `Capacitor.Plugins.Http.get` route, detects server error code 7, and presents an actionable user error and retry button after an attempted chapter load, instead of endless loading. No returned chapter content is fabricated and no cookie/token values are logged.
- **Verified**: Swift syntax, native shortcut patch and JavaScript validation in [workflow 43854378282](https://github.com/duongminhdong0607-bit/stvreader-ios-build/actions/runs/43854378282); iOS Simulator app initialization (theme, search, sync, no JS errors) in [workflow 43852909933](https://github.com/duongminhdong0607-bit/stvreader-ios-build/actions/runs/43852909933).
- **Important blocker**: STV reader's public source code explicitly maps server `code: 7` to `Device not supported` and sometimes misreports it as network failure. Even with the original Android-style HTTP request, an anonymous test did not return chapter content. The server must accept the request for the reader to display real text. This build is not proof that account login or chapter reading works on an actual iPhone.
- **iPhone unsigned IPA**: [combined macOS build run 43854511784](https://github.com/duongminhdong0607-bit/stvreader-ios-build/actions/runs/43854511784). It has not uploaded an IPA yet as of the last status check. Do not distribute prior test IPA as containing this drag fix.
