#!/usr/bin/env python3
"""Recover intact local ZIP entries without inventing missing data."""
from __future__ import annotations
import binascii
import os
import struct
import sys
import zlib
from pathlib import Path

data = Path(sys.argv[1]).read_bytes()
destination = Path(sys.argv[2])
destination.mkdir(parents=True, exist_ok=True)
i = 0
count = 0
total = 0
bad = []
base = "Payload/App.app/public/"
while i + 30 <= len(data) and data[i:i + 4] == b"PK\x03\x04":
    _, version, flags, method, mtime, mdate, crc, csize, usize, nlen, elen = struct.unpack_from("<IHHHHHIIIHH", data, i)
    if flags & 0x8:
        raise SystemExit("Unsupported data descriptor entry: ZIP uses changed archive layout.")
    name = data[i+30:i+30+nlen].decode("utf-8", "replace")
    payload_start = i+30+nlen+elen
    payload_end = payload_start+csize
    if payload_end > len(data):
        print("Missing bytes within:", name, payload_end-len(data))
        break
    if name.startswith(base) and not name.endswith("/"):
        raw = data[payload_start:payload_end]
        try:
            decoded = raw if method == 0 else zlib.decompress(raw, -15)
            if len(decoded) != usize or binascii.crc32(decoded) != crc:
                bad.append(name)
            else:
                relative = name[len(base):]
                target = destination / relative
                if target.resolve().is_relative_to(destination.resolve()):
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(decoded)
                    count += 1
                    total += len(decoded)
        except Exception as error:
            print("CRC/decompress error:",name,str(error))
            bad.append(name)
    i = payload_end

print(f"Recovered {count} original iOS web resource files, {total} bytes. Bad: {len(bad)}")
if count < 20 or not (destination / "index.html").exists():
    raise SystemExit("Original app resources could not be recovered sufficiently.")
