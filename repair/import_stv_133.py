#!/usr/bin/env python3
"""Select only portable STV 1.3.3 assets from the exact verified Android APK.

Android binaries, native-bridge.js, cordova.js and the stale Android index.html
are never copied into iOS. The current official STV application page is loaded
at runtime by the WKWebView from its actual origin.
"""
from __future__ import annotations
from pathlib import Path, PurePosixPath
import hashlib
import sys
import zipfile

APK_SHA256 = "69c64e7caf09a1ad7edf00008065f35dda6eb65ffc0e6779d2a10fa7c1c7de40"
PREFIX = "assets/public/"
PORTABLE = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".ico", ".css", ".ttf", ".woff", ".woff2"}
EXCLUDE = {"assets/public/index.html", "assets/public/cordova.js", "assets/public/cordova_plugins.js"}
MAX_UNCOMPRESSED = 60_000_000

def main():
    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    checksum = hashlib.sha256(source.read_bytes()).hexdigest()
    if checksum != APK_SHA256:
        raise SystemExit(f"APK 1.3.3 does not match user-uploaded source! Actual: {checksum}")
    destination.mkdir(parents=True, exist_ok=True)
    copied, total = [], 0
    with zipfile.ZipFile(source) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Invalid Android APK source")
        for entry in archive.infolist():
            name = entry.filename
            if not name.startswith(PREFIX) or name in EXCLUDE or name.endswith("/"):
                continue
            rel = name[len(PREFIX):]
            part = PurePosixPath(rel)
            if part.is_absolute() or ".." in part.parts or part.suffix.lower() not in PORTABLE:
                continue
            if entry.file_size > 12_000_000 or total + entry.file_size > MAX_UNCOMPRESSED:
                raise SystemExit(f"Unexpectedly large portable asset: {name}")
            target = destination.joinpath(*part.parts)
            if not target.resolve().is_relative_to(destination.resolve()):
                raise SystemExit("Asset path traversal")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(entry))
            total += entry.file_size
            copied.append((str(part), entry.file_size))
    essential = [
        "assets/imgs/logo.png",
        "asset/all.min.css",
        "font/font.css",
        "webfonts/fa-solid-900.woff2"
    ]
    for name in essential:
        if not (destination / name).is_file():
            raise SystemExit(f"Missing essential STV 1.3.3 asset: {name}")
    print(f"Extracted {len(copied)} portable STV 1.3.3 files, {total} bytes")
    for name, size in copied:
        print("STV133", name, size)

if __name__ == "__main__":
    main()
