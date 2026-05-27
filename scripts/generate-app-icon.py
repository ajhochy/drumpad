#!/usr/bin/env python3

"""Generate the SP-808 KILLA app icon, launch mark, and web favicon set.

This generator is intentionally local and deterministic. It does not use a
source image or any external image API, which keeps the app mark original and
regenerable without secrets.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw, ImageFilter
except ModuleNotFoundError as exc:  # pragma: no cover - dependency guard
    raise SystemExit(
        "Missing dependency: Pillow. Install with `pip install pillow`."
    ) from exc


SIZE = 1024
APP_ICON_DIR = Path("ios/SP808Killa/Resources/Assets.xcassets/AppIcon.appiconset")
LAUNCH_MARK_DIR = Path("ios/SP808Killa/Resources/Assets.xcassets/LaunchMark.imageset")


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(lerp(a, b, t) for a, b in zip(c1, c2))


def rounded_rect_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_glow(
    base: Image.Image,
    box: tuple[int, int, int, int],
    color: tuple[int, int, int],
    radius: int,
    opacity: int,
) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(box, radius=radius, fill=(*color, opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(radius))
    base.alpha_composite(layer)


def draw_pixel_sheen(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(34, SIZE, 54):
        alpha = 14 if (y // 54) % 2 else 8
        draw.line((0, y, SIZE, y - 40), fill=(255, 255, 255, alpha), width=2)
    for x in range(26, SIZE, 56):
        draw.line((x, 0, x - 70, SIZE), fill=(0, 0, 0, 14), width=2)


def make_background() -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (9, 10, 13, 255))
    px = img.load()
    top = (26, 29, 36)
    bottom = (7, 9, 12)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        row = mix(top, bottom, t)
        for x in range(SIZE):
            vignette = min(1.0, ((x - SIZE / 2) ** 2 + (y - SIZE / 2) ** 2) ** 0.5 / 720)
            shade = 1.0 - vignette * 0.45
            px[x, y] = (round(row[0] * shade), round(row[1] * shade), round(row[2] * shade), 255)

    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow, "RGBA")
    draw.ellipse((-180, 80, 500, 760), fill=(92, 240, 125, 54))
    draw.ellipse((512, 120, 1220, 800), fill=(255, 42, 122, 58))
    draw.ellipse((260, 600, 860, 1180), fill=(255, 138, 30, 42))
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    img.alpha_composite(glow)
    draw_pixel_sheen(img)
    return img


def draw_device(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img, "RGBA")

    # Chunky shadow and neon underglow.
    draw.rounded_rectangle((154, 244, 900, 870), radius=96, fill=(0, 0, 0, 120))
    paste_glow(img, (174, 214, 874, 836), (255, 42, 122), 84, 88)
    paste_glow(img, (220, 228, 820, 812), (92, 240, 125), 72, 62)

    # Main drum-machine block, deliberately generic and original.
    draw.rounded_rectangle((142, 178, 882, 806), radius=90, fill=(39, 43, 52, 255))
    draw.rounded_rectangle((142, 178, 882, 806), radius=90, outline=(8, 9, 12, 255), width=18)
    draw.rounded_rectangle((174, 204, 850, 778), radius=66, fill=(24, 27, 34, 255))
    draw.rounded_rectangle((174, 204, 850, 778), radius=66, outline=(72, 78, 90, 190), width=7)

    # Top display, sliders, and control strip.
    draw.rounded_rectangle((240, 254, 558, 356), radius=22, fill=(7, 22, 16, 255))
    draw.rounded_rectangle((240, 254, 558, 356), radius=22, outline=(92, 240, 125, 220), width=5)
    for y in (284, 310, 336):
        draw.rectangle((272, y, 520, y + 7), fill=(92, 240, 125, 118))
    for x in (622, 688, 754):
        draw.ellipse((x, 250, x + 56, 306), fill=(15, 17, 22, 255), outline=(255, 138, 30, 210), width=5)
        draw.ellipse((x + 16, 266, x + 40, 290), fill=(255, 138, 30, 220))
    for x in (616, 686, 756):
        draw.rounded_rectangle((x, 324, x + 50, 456), radius=18, fill=(10, 12, 16, 255))
        draw.rounded_rectangle((x + 17, 342, x + 33, 432), radius=6, fill=(82, 87, 98, 255))
        draw.rounded_rectangle((x + 11, 360, x + 39, 396), radius=9, fill=(255, 58, 90, 230))

    # Voxel pad grid.
    pad_colors = [
        (255, 42, 122),
        (92, 240, 125),
        (255, 138, 30),
        (255, 58, 90),
    ]
    start_x, start_y = 246, 424
    pad, gap = 120, 22
    for row in range(3):
        for col in range(4):
            x = start_x + col * (pad + gap)
            y = start_y + row * (pad + gap)
            color = pad_colors[(row + col) % len(pad_colors)]
            shadow = (x + 10, y + 14, x + pad + 10, y + pad + 14)
            rect = (x, y, x + pad, y + pad)
            draw.rounded_rectangle(shadow, radius=24, fill=(0, 0, 0, 104))
            draw.rounded_rectangle(rect, radius=24, fill=(20, 23, 29, 255))
            draw.rounded_rectangle((x + 10, y + 10, x + pad - 10, y + pad - 10), radius=18, fill=(*color, 226))
            draw.rectangle((x + 20, y + 18, x + pad - 24, y + 34), fill=(255, 255, 255, 42))
            draw.rectangle((x + 20, y + pad - 34, x + pad - 20, y + pad - 20), fill=(0, 0, 0, 42))
            paste_glow(img, rect, color, 28, 30)

    # Corner bolts and small LEDs.
    for x, y in ((206, 240), (806, 240), (206, 730), (806, 730)):
        draw.ellipse((x - 18, y - 18, x + 18, y + 18), fill=(9, 10, 13, 255), outline=(97, 103, 116, 210), width=4)
        draw.rectangle((x - 10, y - 2, x + 10, y + 2), fill=(80, 87, 100, 190))
    for i, color in enumerate(((92, 240, 125), (255, 138, 30), (255, 58, 90), (255, 42, 122))):
        x = 278 + i * 44
        draw.ellipse((x, 376, x + 20, 396), fill=(*color, 240))
        paste_glow(img, (x, 376, x + 20, 396), color, 12, 110)

    # Holofoil diagonal sweep.
    sheen = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sheen, "RGBA")
    sdraw.polygon(((182, 172), (338, 172), (888, 760), (754, 812)), fill=(255, 255, 255, 34))
    sdraw.polygon(((518, 190), (580, 190), (876, 504), (876, 590)), fill=(255, 42, 122, 24))
    sdraw.polygon(((170, 448), (228, 392), (566, 780), (498, 780)), fill=(92, 240, 125, 22))
    img.alpha_composite(sheen)


def make_icon() -> Image.Image:
    img = make_background()
    draw_device(img)
    return img.convert("RGB")


def make_launch_mark(master: Image.Image) -> Image.Image:
    transparent = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    mark = master.resize((672, 672), Image.Resampling.LANCZOS).convert("RGBA")
    mask = rounded_rect_mask((672, 672), 136)
    mark.putalpha(mask)
    shadow = Image.new("RGBA", transparent.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle((66, 78, 738, 750), radius=136, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    transparent.alpha_composite(shadow)
    transparent.alpha_composite(mark, (48, 34))
    return transparent


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def save_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def write_app_icon(repo_root: Path, master: Image.Image) -> None:
    out_dir = repo_root / APP_ICON_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    save_png(out_dir / "AppIcon-1024.png", master)
    write_json(
        out_dir / "Contents.json",
        {
            "images": [
                {
                    "filename": "AppIcon-1024.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024",
                }
            ],
            "info": {"author": "xcode", "version": 1},
        },
    )


def write_launch_assets(repo_root: Path, master: Image.Image) -> None:
    out_dir = repo_root / LAUNCH_MARK_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    mark_1x = make_launch_mark(master)
    for scale, size in (("1x", 256), ("2x", 512), ("3x", 768)):
        save_png(out_dir / f"LaunchMark@{scale}.png", mark_1x.resize((size, size), Image.Resampling.LANCZOS))
    write_json(
        out_dir / "Contents.json",
        {
            "images": [
                {"filename": "LaunchMark@1x.png", "idiom": "universal", "scale": "1x"},
                {"filename": "LaunchMark@2x.png", "idiom": "universal", "scale": "2x"},
                {"filename": "LaunchMark@3x.png", "idiom": "universal", "scale": "3x"},
            ],
            "info": {"author": "xcode", "version": 1},
        },
    )


def write_web_favicons(repo_root: Path, master: Image.Image) -> None:
    icon32 = master.resize((32, 32), Image.Resampling.LANCZOS)
    apple = master.resize((180, 180), Image.Resampling.LANCZOS)
    save_png(repo_root / "favicon-32.png", icon32)
    save_png(repo_root / "apple-touch-icon.png", apple)
    (repo_root / "favicon.ico").parent.mkdir(parents=True, exist_ok=True)
    master.save(repo_root / "favicon.ico", format="ICO", sizes=[(16, 16), (32, 32)])


def verify_outputs(paths: Iterable[Path]) -> None:
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        raise RuntimeError(f"Missing generated output(s): {', '.join(missing)}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate SP-808 KILLA app icon assets")
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Repository root (default: parent of scripts/)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    master = make_icon()

    write_app_icon(repo_root, master)
    write_launch_assets(repo_root, master)
    write_web_favicons(repo_root, master)
    verify_outputs(
        [
            repo_root / APP_ICON_DIR / "AppIcon-1024.png",
            repo_root / APP_ICON_DIR / "Contents.json",
            repo_root / LAUNCH_MARK_DIR / "LaunchMark@3x.png",
            repo_root / "favicon.ico",
            repo_root / "favicon-32.png",
            repo_root / "apple-touch-icon.png",
        ]
    )
    print("Generated app icon, launch mark, and favicon assets.")


if __name__ == "__main__":
    main()
