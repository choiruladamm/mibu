#!/usr/bin/env python3
"""Bundle Microsoft Fluent Emoji 3D (MIT) for every icon in the catalog.

Run from apps/mobile after editing lib/domain/emoji_catalog.dart:
  python3 tool/emoji/fetch.py
Writes assets/emoji/<key>.webp (256px), key = hex codepoints without FE0F,
joined by "_" (see AppEmoji), and removes art no longer in the catalog.
Needs `gh` (GitHub API) and `cwebp` (brew install webp).
"""

import concurrent.futures as cf
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request

REPO = "microsoft/fluentui-emoji"
RAW = f"https://raw.githubusercontent.com/{REPO}/main/"
OUT = "assets/emoji"
SIZE = 256  # largest use: the 92px icon in 03.4, ~3x density

# Catalog emoji drawn with another emoji's Fluent art (design's pick).
ART = {"☕": "🍵"}  # kopi: the teacup, not the top-down mug


def key(emoji: str) -> str:
    return "_".join(f"{ord(c):x}" for c in emoji if c != "️")


def used_emoji() -> set[str]:
    """Every icon in the catalog."""
    src = open("lib/domain/emoji_catalog.dart", encoding="utf-8").read()
    return set(re.findall(r"emoji: '([^']+)'", src))


def fetch(url: str, tries: int = 4) -> bytes:
    for i in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                return r.read()
        except OSError:
            if i == tries - 1:
                raise
            time.sleep(2 * (i + 1))


def main() -> None:
    want = {key(e): e for e in used_emoji()}
    tree = json.loads(subprocess.check_output(
        ["gh", "api", f"repos/{REPO}/git/trees/main?recursive=1"]))["tree"]
    paths = [t["path"] for t in tree]
    metas = [p for p in paths if p.startswith("assets/") and p.endswith("/metadata.json")]

    def glyph(meta_path):
        try:
            return meta_path, json.loads(fetch(RAW + urllib.parse.quote(meta_path)))["glyph"]
        except Exception:
            return meta_path, None

    folder = {}  # key → asset folder
    by_glyph = {}  # every Fluent emoji key → its folder
    with cf.ThreadPoolExecutor(32) as pool:
        for meta_path, g in pool.map(glyph, metas):
            if g:
                by_glyph[key(g)] = meta_path.rsplit("/", 1)[0]
    for k, e in want.items():
        src_key = key(ART.get(e, e))
        if src_key in by_glyph:
            folder[k] = by_glyph[src_key]

    os.makedirs(OUT, exist_ok=True)
    missing = []
    for k, e in sorted(want.items()):
        if k not in folder:
            missing.append(e)
            continue
        # Skin-tone emoji keep their 3D art under Default/.
        pngs = [p for p in paths if p.startswith(folder[k] + "/")
                and "/3D/" in p and p.endswith(".png")]
        png = next((p for p in pngs if "/Default/" in p), pngs[0] if pngs else None)
        if png is None:
            missing.append(e)
            continue
        dest = f"{OUT}/{k}.webp"
        if os.path.exists(dest):
            continue
        src = f"{OUT}/{k}.src.png"
        open(src, "wb").write(fetch(RAW + urllib.parse.quote(png)))
        subprocess.run(["cwebp", "-quiet", "-q", "80", "-alpha_q", "90",
                        "-resize", str(SIZE), str(SIZE), src, "-o", dest],
                       check=True)
        os.remove(src)
    for f in os.listdir(OUT):
        # PNG = older format or a half-done download; webp off the catalog.
        if f.endswith(".png") or (f.endswith(".webp") and f[:-5] not in want):
            os.remove(f"{OUT}/{f}")
    print(f"{len(want) - len(missing)} emoji in {OUT}")
    if missing:
        print("no Fluent 3D art for:", " ".join(missing), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
