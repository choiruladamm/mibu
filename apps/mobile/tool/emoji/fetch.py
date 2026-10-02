#!/usr/bin/env python3
"""Bundle Microsoft Fluent Emoji 3D (MIT) for every emoji the app uses.

Run from apps/mobile after adding emoji to the category palette, emojiIdeas
or any other literal in lib/:  python3 tool/emoji/fetch.py
Writes assets/emoji/<key>.png (128px), key = hex codepoints without FE0F,
joined by "_" (see AppEmoji). Needs `gh` (GitHub API) and macOS `sips`.
"""

import concurrent.futures as cf
import glob
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request

REPO = "microsoft/fluentui-emoji"
RAW = f"https://raw.githubusercontent.com/{REPO}/main/"
OUT = "assets/emoji"
SIZE = 128  # largest use is 30px × 3x density


def key(emoji: str) -> str:
    return "_".join(f"{ord(c):x}" for c in emoji if c != "️")


def used_emoji() -> set[str]:
    """Emoji literals in lib/ (category palette, ideas, seeds, fallbacks)."""
    found = set()
    for path in glob.glob("lib/**/*.dart", recursive=True):
        if "/l10n/" in path:
            continue
        for s in re.findall(r"'([^'\n]{1,8})'", open(path, encoding="utf-8").read()):
            if any(0x1F000 <= ord(c) <= 0x1FAFF or 0x2600 <= ord(c) <= 0x27BF
                   for c in s) and not re.search(r"[A-Za-z0-9 ]", s):
                found.add(s)
    return found


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=30) as r:
        return r.read()


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
    with cf.ThreadPoolExecutor(32) as pool:
        for meta_path, g in pool.map(glyph, metas):
            if g and key(g) in want:
                folder[key(g)] = meta_path.rsplit("/", 1)[0]

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
        dest = f"{OUT}/{k}.png"
        open(dest, "wb").write(fetch(RAW + urllib.parse.quote(png)))
        subprocess.run(["sips", "-Z", str(SIZE), dest], check=True,
                       stdout=subprocess.DEVNULL)
    print(f"{len(want) - len(missing)} emoji in {OUT}")
    if missing:
        print("no Fluent 3D art for:", " ".join(missing), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
