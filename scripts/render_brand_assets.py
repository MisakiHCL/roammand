#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""Render committed Roammand platform icons from Quick Look raster sources."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


IOS_ICONS = {
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

MACOS_ICONS = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}

ANDROID_ICONS = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-icon", required=True, type=Path)
    parser.add_argument("--tray-icon", required=True, type=Path)
    parser.add_argument("--root", required=True, type=Path)
    return parser.parse_args()


def resized(source: Image.Image, size: int, *, opaque: bool) -> Image.Image:
    image = source.resize((size, size), Image.Resampling.LANCZOS)
    return image.convert("RGB" if opaque else "RGBA")


def save_set(
    source: Image.Image,
    root: Path,
    assets: dict[str, int],
    *,
    opaque: bool,
) -> None:
    for relative_path, size in assets.items():
        destination = root / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        resized(source, size, opaque=opaque).save(destination, optimize=True)


def main() -> None:
    args = parse_args()
    root = args.root.resolve()
    app_icon = Image.open(args.app_icon).convert("RGBA")
    tray_icon = Image.open(args.tray_icon).convert("RGBA")

    save_set(
        app_icon,
        root / "apps/client_flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset",
        IOS_ICONS,
        opaque=True,
    )
    save_set(
        app_icon,
        root / "apps/client_flutter/macos/Runner/Assets.xcassets/AppIcon.appiconset",
        MACOS_ICONS,
        opaque=False,
    )
    save_set(
        app_icon,
        root / "apps/client_flutter/android/app/src/main/res",
        ANDROID_ICONS,
        opaque=False,
    )

    brand_png = root / "brand/roammand-app-icon-1024.png"
    app_asset = root / "apps/client_flutter/assets/brand/roammand_app_icon.png"
    tray_asset = root / "apps/client_flutter/assets/brand/roammand_tray_template.png"
    brand_png.parent.mkdir(parents=True, exist_ok=True)
    app_asset.parent.mkdir(parents=True, exist_ok=True)
    resized(app_icon, 1024, opaque=True).save(brand_png, optimize=True)
    resized(app_icon, 256, opaque=False).save(app_asset, optimize=True)
    resized(tray_icon, 32, opaque=False).save(tray_asset, optimize=True)

    resized(app_icon, 256, opaque=False).save(
        root / "apps/client_flutter/windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
