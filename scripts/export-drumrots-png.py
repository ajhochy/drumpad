#!/usr/bin/env python3
"""Export art/drumrots/*.webp into the iOS asset catalog as per-drumrot imagesets.

Each `<id>.webp` becomes `Assets.xcassets/drumrots/<id>.imageset/` with a single
universal PNG, so SwiftUI `Image("<id>")` resolves the portrait.
"""
import json, pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "art" / "drumrots"
DEST = ROOT / "ios" / "SP808Killa" / "Resources" / "Assets.xcassets" / "drumrots"
DEST.mkdir(parents=True, exist_ok=True)

count = 0
for webp in sorted(SRC.glob("*.webp")):
    stem = webp.stem
    imageset = DEST / f"{stem}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    png_name = f"{stem}.png"
    Image.open(webp).convert("RGBA").save(imageset / png_name)
    (imageset / "Contents.json").write_text(json.dumps({
        "images": [{"filename": png_name, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    count += 1

# Folder Contents.json so Xcode treats it as a namespaced group.
(DEST / "Contents.json").write_text(json.dumps({
    "info": {"author": "xcode", "version": 1},
    "properties": {"provides-namespace": False},
}, indent=2) + "\n")

print(f"Exported {count} drumrot imagesets -> {DEST.relative_to(ROOT)}")
