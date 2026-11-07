#!/bin/sh
# KDE -> repo: save the current values of the settings listed in
# fedora/prefs/kde and fedora/prefs/konsole-shortcuts back into those files.
# Runs automatically after `chezmoi re-add` on Linux (hook in
# home/.chezmoi.toml.tmpl); can also be run by hand. Commit the result.
#
# Repo -> KDE is the counterpart, run by `chezmoi apply`:
# home/.chezmoiscripts/run_onchange_after_kde-prefs-apply.sh.tmpl
#
# Only listed settings are saved. To help find new ones, it also prints
# settings that changed since the last run in the files fedora/prefs/kde
# already uses, as lines ready to paste into it. It keeps the comparison copy
# in ~/.cache/dotfiles/ and never adds anything to the repo by itself.

set -eu

# Nothing to do on a machine without KDE.
command -v kreadconfig6 >/dev/null 2>&1 || exit 0

repo=$(cd "$(dirname "$0")/.." && pwd)

python3 -I - "$repo/fedora/prefs" "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/kde-snapshot.tsv" <<'EOF'
import os, re, subprocess, sys

prefs_dir, snapshot_path = sys.argv[1], sys.argv[2]
home = os.path.expanduser("~")
DEFAULT = "(default)"


def real_path(file):
    if file.startswith("~/"):
        return os.path.join(home, file[2:])
    return os.path.join(home, ".config", file)


def group_args(group):
    args = []
    for part in group[1:-1].split("]["):
        args += ["--group", part]
    return args


def data_lines(path):
    """(index, fields) for each non-comment line of a tab-separated prefs file."""
    lines = open(path, encoding="utf-8").read().split("\n")
    rows = [(i, line.split("\t")) for i, line in enumerate(lines)
            if line.strip() and not line.lstrip().startswith("#")]
    return lines, rows


def save(path, lines):
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# KDE settings
kde_path = os.path.join(prefs_dir, "kde")
lines, rows = data_lines(kde_path)
tracked = set()
for i, (file, group, key, value) in rows:
    tracked.add((file, group, key))
    current = subprocess.run(
        ["kreadconfig6", "--file", real_path(file), *group_args(group),
         "--key", key, "--default", DEFAULT],
        capture_output=True, text=True, check=True).stdout.rstrip("\n")
    if current != value:
        print(f"saved: {file} {group} {key}: {value} -> {current}")
        lines[i] = "\t".join([file, group, key, current])
save(kde_path, lines)

# Konsole shortcuts
ui_dir = os.path.join(home, ".local/share/kxmlgui5/konsole")
shortcuts_path = os.path.join(prefs_dir, "konsole-shortcuts")
lines, rows = data_lines(shortcuts_path)
for i, (ui, action, value) in rows:
    current = DEFAULT
    ui_path = os.path.join(ui_dir, ui + ".rc")
    if os.path.exists(ui_path):
        text = open(ui_path, encoding="utf-8").read()
        props = re.search(r'<ActionProperties scheme="Default">(.*?)</ActionProperties>', text, re.S)
        if props:
            for attrs in re.findall(r"<Action\b([^>]*)/?>", props.group(1)):
                name = re.search(r'\bname=["\']([^"\']*)', attrs)
                shortcut = re.search(r'\bshortcut=["\']([^"\']*)', attrs)
                if name and name.group(1) == action and shortcut:
                    current = shortcut.group(1)
    if current != value:
        print(f"saved: konsole {ui} {action}: {value} -> {current}")
        lines[i] = "\t".join([ui, action, current])
save(shortcuts_path, lines)


# Hints: untracked settings that changed since the last run, in the files
# fedora/prefs/kde already uses.
def read_ini(path):
    entries, group = {}, None
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return entries
    for line in text.split("\n"):
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            group = line
        elif group and "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            entries[(group, key)] = value
    return entries


snapshot = {}
for file in sorted({file for file, _, _ in tracked}):
    for (group, key), value in read_ini(real_path(file)).items():
        snapshot[(file, group, key)] = value

if os.path.exists(snapshot_path):
    old = {}
    for line in open(snapshot_path, encoding="utf-8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) == 4:
            old[tuple(parts[:3])] = parts[3]
    hints = [(*k, v) for k, v in sorted(snapshot.items())
             if old.get(k) != v and k not in tracked and not k[1].startswith("[Tiling]")]
    if hints:
        print("\nChanged since the last re-add and not synced. To sync one, paste its line")
        print("into fedora/prefs/kde, then run `chezmoi re-add` again:\n")
        for hint in hints:
            print("\t".join(hint))
else:
    print("kde: saved a snapshot; the next re-add lists settings changed after now")

os.makedirs(os.path.dirname(snapshot_path), exist_ok=True)
with open(snapshot_path, "w", encoding="utf-8") as f:
    for k, v in sorted(snapshot.items()):
        f.write("\t".join([*k, v]) + "\n")
EOF
