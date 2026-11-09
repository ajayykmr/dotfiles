"""Find and extract the images in a Google Doc, with a per-machine cache.

Part of the read-gdocs skill. The cache records, per doc ID, the doc's
modifiedTime and how many images it had at the last check, so a doc without
images is not exported again until it changes. It lives in
$XDG_CACHE_HOME/read-gdocs/docs.json (default ~/.cache/read-gdocs/docs.json)
and is safe to delete.

Workaround: neither the Drive connector's read_file_content nor the Google
Docs connector's read_doc returns images (tested 2026-11). Once either does,
use it and remove this script.

Commands:
  cached DOC_ID MODIFIED_TIME
      Print the cached result for the doc, or "not cached" if there is none
      or the doc changed since.
  extract [--doc-id ID --modified-time TIME] EXPORT OUT_DIR
      Save the images in a Google Docs HTML export (as saved by the Drive
      connector) to OUT_DIR. Prints one line per image: the saved file, pixel
      size, file size, and the text just before it in the doc. With --doc-id
      and --modified-time, also records the result in the cache.
  record [--images N] [--title TITLE] DOC_ID MODIFIED_TIME
      Record a result without an export file (default: no images). Used when
      the export came back inline: such small exports are treated as having
      no images.
"""
import argparse
import base64
import datetime
import html
import json
import os
import re
import struct
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# cache

def cache_path():
    base = os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache"
    return Path(base) / "read-gdocs" / "docs.json"


def load_cache():
    try:
        return json.loads(cache_path().read_text())
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as e:
        print(f"warning: ignoring unreadable cache {cache_path()}: {e}", file=sys.stderr)
        return {}


def save_cache(cache):
    path = cache_path()
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n")
        tmp.replace(path)
    except OSError as e:
        print(f"warning: could not write cache {path}: {e}", file=sys.stderr)


# ---------------------------------------------------------------------------
# image extraction

def image_size(data):
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", data[16:24])
    if data[:4] == b"GIF8":
        return struct.unpack("<HH", data[6:10])
    if data[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(data):
            marker, length = data[i + 1], struct.unpack(">H", data[i + 2:i + 4])[0]
            if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
                h, w = struct.unpack(">HH", data[i + 5:i + 9])
                return w, h
            i += 2 + length
    return None


def text_before(page, pos):
    # Clean the whole prefix: a fixed window can start inside an earlier
    # image's base64 or a tag's style attribute and print that instead.
    prefix = re.sub(r"(?s)<(style|head)[^>]*>.*?</\1>", " ", page[:pos])
    prefix = re.sub(r"<img[^>]*>", " ", prefix)
    prefix = re.sub(r"<[^>]+>", " ", prefix)
    return " ".join(html.unescape(prefix[-3000:]).split())[-150:]


def is_spacer(size):
    # Docs exports carry 1x1 GIFs as layout spacers; they are not content.
    return size is not None and size[0] <= 2 and size[1] <= 2


# ---------------------------------------------------------------------------
# commands

def cmd_cached(args):
    entry = load_cache().get(args.doc_id)
    if entry and entry.get("modified_time") == args.modified_time:
        print(f"images: {entry['images']} (cached, checked {entry['checked']})")
    elif entry:
        print("not cached: the doc changed since the last check")
    else:
        print("not cached")
    return 0


def cmd_extract(args):
    doc = json.loads(Path(args.export).read_text())
    content = doc["content"]
    try:
        page = base64.b64decode(content, validate=True).decode("utf-8")
    except Exception:
        page = content

    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    images = []
    spacers = 0
    for m in re.finditer(r'<img[^>]*src="data:image/(\w+);base64,([^"]+)"', page):
        data = base64.b64decode(m.group(2))
        size = image_size(data)
        if is_spacer(size):
            spacers += 1
        else:
            images.append((m, data, size))

    print(f"title: {doc.get('title')}")
    print(f"images: {len(images)}" + (f" (skipped {spacers} spacer)" if spacers else ""))
    for i, (m, data, size) in enumerate(images, 1):
        path = out / f"image-{i}.{m.group(1)}"
        path.write_bytes(data)
        before = text_before(page, m.start())
        dims = f"{size[0]}x{size[1]}" if size else "?"
        print(f"{path} | {dims} | {len(data) // 1024} KB | after: ...{before}")

    if args.doc_id:
        record(args.doc_id, args.modified_time, len(images), doc.get("title"))
    return 0


def cmd_record(args):
    record(args.doc_id, args.modified_time, args.images, args.title)
    print(f"recorded images: {args.images} for {args.doc_id}")
    return 0


def record(doc_id, modified_time, images, title=None):
    cache = load_cache()
    cache[doc_id] = {
        "title": title,
        "modified_time": modified_time,
        "images": images,
        "checked": datetime.date.today().isoformat(),
    }
    save_cache(cache)


def main():
    parser = argparse.ArgumentParser(
        prog="gdoc_images.py",
        description="Find and extract the images in a Google Doc, with a per-machine cache.",
    )
    sub = parser.add_subparsers(dest="command", required=True, metavar="COMMAND")

    p = sub.add_parser("cached", help="print the cached result for a doc")
    p.add_argument("doc_id", metavar="DOC_ID", help="the ID in the doc's URL")
    p.add_argument("modified_time", metavar="MODIFIED_TIME", help="modifiedTime from get_file_metadata")
    p.set_defaults(func=cmd_cached)

    p = sub.add_parser("extract", help="save the images in a saved HTML export")
    p.add_argument("export", metavar="EXPORT", help="the export file saved by download_file_content")
    p.add_argument("out_dir", metavar="OUT_DIR", help="folder to save the images in")
    p.add_argument("--doc-id", help="record the result in the cache under this doc ID")
    p.add_argument("--modified-time", help="the doc's modifiedTime, required with --doc-id")
    p.set_defaults(func=cmd_extract)

    p = sub.add_parser("record", help="record a result in the cache without an export file")
    p.add_argument("doc_id", metavar="DOC_ID", help="the ID in the doc's URL")
    p.add_argument("modified_time", metavar="MODIFIED_TIME", help="modifiedTime from get_file_metadata")
    p.add_argument("--images", type=int, default=0, help="number of images to record (default: 0)")
    p.add_argument("--title", help="the doc's title, for reading the cache")
    p.set_defaults(func=cmd_record)

    args = parser.parse_args()
    if args.command == "extract" and bool(args.doc_id) != bool(args.modified_time):
        parser.error("--doc-id and --modified-time must be given together")
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
