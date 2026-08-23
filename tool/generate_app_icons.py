"""Generate platform app icons from assets/branding/maylesoft_logo.png."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "branding" / "maylesoft_logo.png"
BG = (248, 250, 252)


def make_icon(size: int, *, padding_ratio: float = 0.08) -> Image.Image:
    src = Image.open(SOURCE).convert("RGBA")
    canvas = Image.new("RGBA", (size, size), (*BG, 255))
    pad = max(1, int(size * padding_ratio))
    inner = size - pad * 2
    fitted = src.copy()
    fitted.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    x = (size - fitted.width) // 2
    y = (size - fitted.height) // 2
    canvas.paste(fitted, (x, y), fitted)
    return canvas


def save_png(path: Path, size: int, *, padding_ratio: float = 0.08) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    make_icon(size, padding_ratio=padding_ratio).save(path, format="PNG")


def save_ico(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = [make_icon(s, padding_ratio=0.08) for s in sizes]
    images[0].save(
        path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=images[1:],
    )


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source logo: {SOURCE}")

    # Windows
    save_ico(ROOT / "windows" / "runner" / "resources" / "app_icon.ico")

    # Android
    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android.items():
        save_png(ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png", size)

    # macOS
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save_png(
            ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / f"app_icon_{size}.png",
            size,
        )

    # iOS
    ios_icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for filename, size in ios_icons.items():
        save_png(ios_dir / filename, size)

    # Web
    save_png(ROOT / "web" / "favicon.png", 32)
    save_png(ROOT / "web" / "icons" / "Icon-192.png", 192)
    save_png(ROOT / "web" / "icons" / "Icon-512.png", 512)
    save_png(ROOT / "web" / "icons" / "Icon-maskable-192.png", 192, padding_ratio=0.18)
    save_png(ROOT / "web" / "icons" / "Icon-maskable-512.png", 512, padding_ratio=0.18)

    print("Generated app icons from", SOURCE.name)


if __name__ == "__main__":
    main()
