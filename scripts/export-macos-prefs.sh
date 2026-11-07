#!/bin/sh
# Export macOS app preferences into macos/prefs/ as XML plists.
# Runs automatically after `chezmoi re-add` on macOS (hook in
# home/.chezmoi.toml.tmpl); can also be run by hand. Commit the result.
# `chezmoi apply` imports them back (see home/.chezmoiscripts).
#
# Volatile keys (update checks, window frames, version stamps) are stripped
# so the files only change when a real setting changes.
#
# iTerm2 is not handled here: it reads and writes macos/iterm2/ directly.

set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
out="$repo/macos/prefs"
mkdir -p "$out"

domains=$(grep -v '^#' "$out/apps" | awk 'NF == 2 { print $2 }')

for domain in $domains; do
  if ! defaults export "$domain" - >/dev/null 2>&1; then
    echo "skip: $domain (not readable)" >&2
    continue
  fi
  defaults export "$domain" - | python3 -I -c '
import plistlib, sys

volatile_prefixes = ("SU", "NSWindow Frame", "NSStatusItem", "NSNavPanel",
                     "NSSplitView", "NSToolbar", "NSOSPLastRootDirectory")
volatile_keys = {"installVersion", "lastVersion", "OriginalAccel"}

d = plistlib.loads(sys.stdin.buffer.read())
d = {k: v for k, v in d.items()
     if not k.startswith(volatile_prefixes) and k not in volatile_keys}
sys.stdout.buffer.write(plistlib.dumps(d, fmt=plistlib.FMT_XML, sort_keys=True))
' > "$out/$domain.plist.tmp"
  mv "$out/$domain.plist.tmp" "$out/$domain.plist"
  echo "exported: $domain"
done
