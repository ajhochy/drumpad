#!/usr/bin/env python3

"""Batch generator for drumrot parody images via the nano-banana model.

Usage examples:
  python scripts/generate-drumrots.py              # process every entry
  python scripts/generate-drumrots.py --id 005     # just Bassolo Gorillini
  python scripts/generate-drumrots.py --id 005 --id 018

Set the environment variable OPENROUTER_API_KEY (preferred) or NANOBANANA_API_KEY
with your OpenRouter key first.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Mapping, MutableMapping, Sequence

try:
    import requests
except ModuleNotFoundError as exc:  # pragma: no cover - dependency guard
    raise SystemExit(
        "Missing dependency: requests. Install with `pip install requests`."
    ) from exc

try:
    from PIL import Image
except ModuleNotFoundError as exc:  # pragma: no cover - dependency guard
    raise SystemExit(
        "Missing dependency: Pillow. Install with `pip install pillow`."
    ) from exc


PROMPT_TEMPLATE = (
    "Edit this image. Keep the exact same character, pose, art style, color palette, "
    "and proportions. Transform it into a drum-and-percussion themed version called "
    "\"{name}\" - {sub}. Add drumsticks held in the character's hands or paws, a small "
    "drum kit element nearby (snare, tom, or cymbal as fits the character), and subtle "
    "music-note or sparkle accents. Keep the background simple and clean - solid or "
    "softly gradient, not busy. Square 1:1 composition. Do not add text or watermarks. "
    "The character must remain instantly recognizable as a parody of the original."
)


@dataclass
class DrumrotEntry:
    id: str
    name: str
    sub: str
    parody_img: str


class DrumrotGenerator:
    def __init__(self, repo_root: Path, api_key: str, delay_ms: int = 500):
        self.repo_root = repo_root
        self.api_key = api_key
        self.delay_ms = delay_ms
        self.session = requests.Session()

    def run(self, entries: Sequence[DrumrotEntry]) -> None:
        if not entries:
            print("No drumrots to process.")
            return

        output_dir = self.repo_root / "art" / "drumrots"
        output_dir.mkdir(parents=True, exist_ok=True)

        js_path = self.repo_root / "js" / "drumrots.js"

        successes: list[str] = []
        skipped: list[str] = []
        start_time = time.perf_counter()

        for idx, entry in enumerate(entries, start=1):
            print(f"[{idx}/{len(entries)}] {entry.id}: starting")
            try:
                image_bytes = self._edit_image(entry)
                if not image_bytes:
                    raise RuntimeError("Empty response from nano-banana")

                output_path = output_dir / f"{entry.id}.webp"
                processed = self._process_image(image_bytes, output_path)
                if processed:
                    print(f"[{idx}/{len(entries)}] {entry.id}: saved {output_path.relative_to(self.repo_root)}")
                    successes.append(entry.id)
                else:
                    raise RuntimeError("Unable to convert response into WEBP")
            except Exception as exc:  # noqa: BLE001 - log and continue
                print(f"[{idx}/{len(entries)}] {entry.id}: failed ({exc})")
                skipped.append(entry.id)
            finally:
                # polite delay
                time.sleep(self.delay_ms / 1000.0)

        if successes:
            self._update_js(js_path, entries, set(successes))

        elapsed = time.perf_counter() - start_time
        size_bytes = self._directory_size(output_dir)

        print("\n=== Drumrot batch summary ===")
        print(f"Generated: {len(successes)}")
        print(f"Skipped: {len(skipped)}" + (f" — {', '.join(skipped)}" if skipped else ""))
        print(f"Elapsed: {elapsed:.1f}s")
        print(f"Output size: {size_bytes / 1024:.1f} KiB")

    def _edit_image(self, entry: DrumrotEntry) -> bytes:
        source_path = self.repo_root / entry.parody_img
        if not source_path.exists():
            raise FileNotFoundError(f"Missing source image: {source_path}")

        with source_path.open("rb") as fh:
            encoded = base64.b64encode(fh.read()).decode("ascii")

        prompt = PROMPT_TEMPLATE.format(name=entry.name, sub=entry.sub)

        payload = {
            "model": "google/gemini-2.5-flash-image",
            "modalities": ["image", "text"],
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/png;base64,{encoded}"
                            },
                        },
                    ],
                }
            ],
        }

        url = "https://openrouter.ai/api/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/ajhochy/drumpad",
            "X-Title": "drumrot batch generator",
        }
        response = self.session.post(url, headers=headers, json=payload, timeout=180)

        if response.status_code >= 300:
            raise RuntimeError(f"API error {response.status_code}: {response.text}")

        data = response.json()
        try:
            message = data["choices"][0]["message"]
        except (KeyError, IndexError) as exc:
            raise RuntimeError(f"Unexpected API payload: {json.dumps(data)[:400]}") from exc

        for image in message.get("images") or []:
            url_value = (image.get("image_url") or {}).get("url", "")
            if url_value.startswith("data:") and "base64," in url_value:
                return base64.b64decode(url_value.split("base64,", 1)[1])

        content = message.get("content")
        if isinstance(content, list):
            for part in content:
                if part.get("type") == "image_url":
                    url_value = (part.get("image_url") or {}).get("url", "")
                    if url_value.startswith("data:") and "base64," in url_value:
                        return base64.b64decode(url_value.split("base64,", 1)[1])

        raise RuntimeError(f"No image found in API response: {json.dumps(data)[:400]}")

    def _process_image(self, image_bytes: bytes, output_path: Path) -> bool:
        stream = io.BytesIO(image_bytes)
        try:
            image = Image.open(stream)
        except Exception as exc:  # noqa: BLE001 - provide context
            raise RuntimeError(f"Pillow could not open image: {exc}")

        image = image.convert("RGBA")
        image = image.resize((384, 384), Image.Resampling.LANCZOS)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(output_path, format="WEBP", quality=82, method=6)
        return True

    def _update_js(self, js_path: Path, entries: Sequence[DrumrotEntry], success_ids: set[str]) -> None:
        text = js_path.read_text(encoding="utf-8")
        updated = text
        for entry in entries:
            if entry.id not in success_ids:
                continue
            pattern = re.compile(
                r"(parodyImg:\s*'" + re.escape(entry.parody_img) + r"'\s*,)(?!\s*\n\s*drumrotImg:)"
            )
            replacement = r"\1\n    drumrotImg: 'art/drumrots/" + entry.id + r".webp',"
            updated, count = pattern.subn(replacement, updated, count=1)
            if count == 0:
                # Already present or pattern mismatch; leave untouched and warn.
                print(f"Warning: could not inject drumrotImg for {entry.id}; check formatting manually.")

        if updated != text:
            js_path.write_text(updated, encoding="utf-8")

    @staticmethod
    def _directory_size(directory: Path) -> int:
        total = 0
        if directory.exists():
            for file in directory.glob("*.webp"):
                total += file.stat().st_size
        return total


def load_drumrots(js_path: Path) -> list[DrumrotEntry]:
    text = js_path.read_text(encoding="utf-8")
    match = re.search(r"export const DRUMROTS = \[", text)
    if not match:
        raise RuntimeError("Could not locate DRUMROTS array in js/drumrots.js")

    entries: list[DrumrotEntry] = []
    entry_re = re.compile(r"{\s*id:\s*'([^']+)'(.*?)\n\s*}\s*,?", re.DOTALL)

    for obj in entry_re.finditer(text[match.end() :]):
        block = obj.group(2)
        name = _extract_field(block, "name")
        sub = _extract_field(block, "sub")
        parody_img = _extract_field(block, "parodyImg")
        entries.append(DrumrotEntry(id=obj.group(1), name=name, sub=sub, parody_img=parody_img))

    if not entries:
        raise RuntimeError("No entries parsed from DRUMROTS")
    return entries


def _extract_field(block: str, field: str) -> str:
    pattern = re.compile(rf"{field}:\s*'([^']+)'")
    match = pattern.search(block)
    if not match:
        raise RuntimeError(f"Missing `{field}` in block: {block[:120]}...")
    return match.group(1)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate drumrot parody art via nano-banana")
    parser.add_argument(
        "--id",
        dest="ids",
        action="append",
        help="Process only the specified drumrot id (repeatable)",
    )
    parser.add_argument(
        "--delay",
        type=int,
        default=500,
        help="Delay between API calls in milliseconds (default: 500)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> None:
    args = parse_args(argv or sys.argv[1:])
    repo_root = Path(__file__).resolve().parents[1]
    js_path = repo_root / "js" / "drumrots.js"

    entries = load_drumrots(js_path)
    if args.ids:
        requested = set(args.ids)
        entries = [entry for entry in entries if entry.id in requested]
        missing = requested - {entry.id for entry in entries}
        if missing:
            print(f"Warning: unknown drumrot id(s): {', '.join(sorted(missing))}")

    if not entries:
        print("Nothing to do — no matching drumrot ids.")
        return

    api_key = os.environ.get("OPENROUTER_API_KEY") or os.environ.get("NANOBANANA_API_KEY")
    if not api_key:
        raise SystemExit(
            "Set OPENROUTER_API_KEY (or NANOBANANA_API_KEY) before running."
        )

    generator = DrumrotGenerator(repo_root=repo_root, api_key=api_key, delay_ms=args.delay)
    generator.run(entries)


if __name__ == "__main__":
    main()
