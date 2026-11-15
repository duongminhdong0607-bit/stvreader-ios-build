# STV MobileReader — Capacitor iOS reconstruction experiment

This branch rebuilds a **new iOS Capacitor app**, rather than using the 1.3.2 executable that is missing 17 native frameworks. It is based on the publisher's app metadata and attempts to reuse the original web UI resource files recovered from the official IPA.

**Original source**: https://staticvn.sangtacvietcdn.xyz/download/stvmobilereader-1.3.2.ipa — 12,648,448 bytes, truncated as served by publisher.

**Known official app URL**: https://sangtacviet.com/app.v2.php (recovered from Android app config v1.2.17).

## Included native functionality
Capacitor iOS plugins for storage, SQLite, Filesystem, clipboard, camera, browser, app state, sharing, vibration/haptics and speech synthesis. Exact plugin runtime compatibility with STV v1.3.2 cannot be guaranteed; custom CordovaPlugins and publisher-only plugins not available.

- Automatic builds in GitHub Actions on branch stv-capacitor-rebuild.
- The generated IPA is **unsigned**, intended for signing with Sideloadly on Windows.
- No user credentials, provisioning files or private Apple keys are stored.
- This reconstruction is not an official STV MobileReader release; online/login capabilities depend on STV servers. Never claim same app or guarantee usability without device tests.

## Why the damaged IPA cannot be patched directly
The original IPA published by the CDN lacks its central ZIP directory and all 17 dynamic iOS framework executables, including proprietary CordovaPlugins. No APK contains iOS Mach-O binaries, so Android ELF .so files cannot be used in an iOS IPA. Mere ZIP repair does not supply native dependencies.
