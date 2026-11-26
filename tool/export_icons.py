"""Export witor's platform icons from its transparent brand mark using ImageMagick 6."""
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARK = ROOT / "assets/brand/witor-mark.png"
RES = ROOT / "android/app/src/main/res"


def convert(*args):
    subprocess.run(["convert", *map(str, args)], check=True)


def resize(source, target, size, opaque=False):
    target.parent.mkdir(parents=True, exist_ok=True)
    convert(source, "-resize", f"{size}x{size}", "-strip",
            ("PNG24:" if opaque else "PNG32:") + str(target))


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        face, tile, mac = (tmp / f"{n}.png" for n in ("face", "tile", "mac"))
        convert("-size", "1024x1024", "gradient:#204350-#0C202C",
                "(", MARK, "-resize", "730x730", ")", "-gravity", "center",
                "-geometry", "+0+16", "-composite", face)
        convert(face, "(", "-size", "1024x1024", "xc:black", "-fill", "white",
                "-draw", "roundrectangle 0,0 1023,1023 220,220", "-alpha", "off", ")",
                "-compose", "CopyOpacity", "-composite", tile)
        convert(tile, "-resize", "836x836", "-background", "none", "-gravity",
                "center", "-extent", "1024x1024", mac)
        resize(tile, ROOT / "assets/witor.png", 256)
        for os, source in [("ios", face), ("macos", mac)]:
            catalog = ROOT / os / "Runner/Assets.xcassets/AppIcon.appiconset"
            images = json.loads((catalog / "Contents.json").read_text())["images"]
            for icon in {row["filename"]: row for row in images}.values():
                size = float(icon["size"].split("x")[0]) * float(icon["scale"][:-1])
                resize(source, catalog / icon["filename"], int(size), opaque=os == "ios")
        for ratio, bucket in [(1, "mdpi"), (1.5, "hdpi"), (2, "xhdpi"),
                              (3, "xxhdpi"), (4, "xxxhdpi")]:
            resize(tile, RES / f"mipmap-{bucket}/ic_launcher.png", int(48 * ratio))
            # The same alpha silhouette serves Android's themed and adaptive icons.
            layer = RES / f"drawable-{bucket}/witor_foreground.png"
            layer.parent.mkdir(parents=True, exist_ok=True)
            side = int(108 * ratio)
            convert(MARK, "-resize", str(round(59 * ratio)), "-background", "none",
                    "-gravity", "center", "-extent", f"{side}x{side}", "-strip", "PNG32:" + str(layer))
        for scale, suffix in [(1, ""), (2, "@2x"), (3, "@3x")]:
            launch = ROOT / f"ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png"
            side = 104 * scale
            convert(MARK, "-resize", str(side), "-gravity", "center", "-background", "none",
                    "-extent", f"{side}x{side}", "-strip", "PNG32:" + str(launch))
        convert(tile, "-define", "icon:auto-resize=256,128,64,48,32,24,16",
                ROOT / "windows/runner/resources/app_icon.ico")


if __name__ == "__main__":
    main()
