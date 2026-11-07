# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Works on macOS and Fedora (KDE Plasma).

## Layout

```
home/                 chezmoi source (maps to ~), see .chezmoiroot
  .chezmoi.toml.tmpl  chezmoi config (points chezmoi at this repo)
  .chezmoiexternal.toml.tmpl   oh-my-zsh, powerlevel10k, zsh plugins; Linux: CaskaydiaCove Nerd Font (fetched if missing)
  .chezmoiscripts/    scripts chezmoi runs during apply (see below)
macos/Brewfile        apps and tools this repo depends on (installed by apply)
macos/iterm2/         iTerm2 reads and writes its prefs here directly
macos/prefs/          app settings as plists (Rectangle, UnnaturalScrollWheels)
fedora/packages       dnf packages (installed by apply)
fedora/flatpaks       Flathub apps (installed by apply)
fedora/repos/         repos the packages need: vendor .repo files, COPRs
fedora/prefs/         KDE settings and Konsole shortcuts, only the ones changed from the defaults
scripts/              settings, machine -> repo: macos-prefs-re-add.sh, kde-prefs-re-add.sh
```

Scripts in `home/.chezmoiscripts/` run during `chezmoi apply`. The filename
prefix tells chezmoi when: `run_once_` runs once per machine, `run_onchange_`
whenever the script's content changes, `before_`/`after_` around writing files.
Scripts in the same phase run in alphabetical order.

| Script | Does |
|---|---|
| `run_onchange_before_brew-bundle` | macOS: installs what's missing from `macos/Brewfile` |
| `run_once_after_iterm2-prefs-folder` | macOS: points iTerm2 at `macos/iterm2/` |
| `run_onchange_after_macos-prefs-apply` | macOS: app settings, repo -> Mac (counterpart of `scripts/macos-prefs-re-add.sh`) |
| `run_onchange_before_fedora-packages` | Fedora: adds the repos, installs what's missing from `fedora/packages` and `fedora/flatpaks`, sets zsh as login shell |
| `run_onchange_after_kde-install-themes` | KDE: installs the themes the settings use, if missing (Layan, Tela icons, Layan cursors, Kuro splash) |
| `run_onchange_after_kde-prefs-apply` | KDE: settings, repo -> KDE (counterpart of `scripts/kde-prefs-re-add.sh`) |

The KDE scripts only run inside a Plasma session. Run from SSH or a TTY, they are
skipped and run at the next `chezmoi apply` inside Plasma.

Managed: zsh (`.zshrc`, `.zshenv`, `.p10k.zsh`), nvim (LazyVim), Claude Code (`CLAUDE.md`),
iTerm2, Rectangle, UnnaturalScrollWheels, KDE Plasma (theme, effects, power, input, Konsole).

## Not tracked (per machine)

- `~/.zshrc.local`, `~/.zshenv.local`: work aliases, paths, `KUBECONFIG`, etc.
- Fedora: NVIDIA driver (hardware-specific), wallpapers, panel layout (see below).

## New machine

### macOS

Needs [Homebrew](https://brew.sh) first. Clone this repo anywhere (`~/personal/dotfiles` below), then:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
git clone <repo-url> ~/personal/dotfiles
~/.local/bin/chezmoi init --source ~/personal/dotfiles
~/.local/bin/chezmoi diff
~/.local/bin/chezmoi apply
```

After the first apply, open a new shell so `~/.local/bin` is on `PATH`.

### Fedora (KDE Plasma)

From a terminal inside the Plasma session:

```
sudo dnf install git chezmoi
git clone <repo-url> ~/dotfiles
chezmoi init --source ~/dotfiles
chezmoi diff
chezmoi apply
```

`apply` asks for the sudo password (packages, repos, login shell), installs the themes and
loads the KDE settings. Log out and back in afterwards.

NVIDIA driver, if the machine has an NVIDIA GPU (RPM Fusion is already set up by `apply`):

```
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

Panel layout is not synced: Plasma stores it per screen, with internal IDs. To recreate it,
on each screen:

- Top bar: application launcher, global menu, clock in the center, system tray
- Bottom dock: floating, translucent, visibility "Dodge windows", icon-only task manager

For another monitor, use "Clone Panel" in the panel's Edit Mode.

## Day to day

```
chezmoi diff
chezmoi apply
chezmoi re-add
chezmoi edit ~/.zshrc
chezmoi cd
```

- `diff`: what `apply` would change in `~`
- `apply`: write the repo state into `~`
- `re-add`: pull edits made directly in `~` back into the repo (non-template files only).
  On macOS it also saves Rectangle and UnnaturalScrollWheels settings
  (`scripts/macos-prefs-re-add.sh`). iTerm2 saves into the repo by itself.
  On Fedora it also saves the KDE settings and Konsole shortcuts listed in `fedora/prefs/`
  (`scripts/kde-prefs-re-add.sh`).
- `edit`: edit the source copy; needed for templates (`.zshrc`)
- `cd`: open a shell in the repo

## KDE settings

`fedora/prefs/kde` lists only the settings changed from KDE's defaults, one per line:
file, group, key, value (tab-separated). Theme colors, window decoration and cursors come from
the Layan global theme, so they are not listed. `fedora/prefs/konsole-shortcuts` does the same
for Konsole shortcuts (Konsole keeps those in XML files, not KDE config files).

- Change a listed setting in System Settings or Konsole, then `chezmoi re-add`: the new value
  is saved into `fedora/prefs/`. Check with `git diff`, then commit.
- To sync a setting that isn't listed, add its line. `re-add` helps: it also prints the
  settings that changed since its last run, in the files `fedora/prefs/kde` already uses, as
  lines ready to paste. Settings in other files: find the file in `~/.config` that changed and
  write the line by hand.
- `chezmoi diff` doesn't show KDE settings. To see what changed locally, run `chezmoi re-add`
  and `git diff`.
- When `fedora/prefs/` changes (after `re-add`, or a pull from another machine), the next
  `apply` writes every listed setting, without asking. Run `re-add` before pulling if you
  changed settings on this machine.
- Touchpad settings (natural scrolling, click method, scroll speed) are in the apply script:
  KDE stores them per touchpad model, so the script finds the machine's touchpads.

Themes are installed only when missing, so they don't update by themselves. To update one,
delete its folder (see `run_onchange_after_kde-install-themes`) and run `chezmoi apply`. A
reinstalled Layan overwrites the transparency fix in `fedora/prefs/kde`; load the settings
again with:

```
chezmoi execute-template < "$(chezmoi source-path)/.chezmoiscripts/run_onchange_after_kde-prefs-apply.sh.tmpl" | bash
```
