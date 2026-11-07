# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Works on macOS and Fedora.

## Layout

```
home/                 chezmoi source (maps to ~), see .chezmoiroot
  .chezmoi.toml.tmpl  chezmoi config (points chezmoi at this repo)
  .chezmoiexternal.toml   oh-my-zsh, powerlevel10k, zsh plugins (cloned if missing)
  .chezmoiscripts/    macOS-only scripts chezmoi runs during apply (see below)
macos/Brewfile        apps and tools this repo depends on (installed by apply)
macos/iterm2/         iTerm2 reads and writes its prefs here directly
macos/prefs/          app settings as plists (Rectangle, UnnaturalScrollWheels)
scripts/              macos-prefs-re-add.sh: app settings, Mac -> repo
```

Scripts in `home/.chezmoiscripts/` run during `chezmoi apply`. The filename
prefix tells chezmoi when: `run_once_` runs once per machine, `run_onchange_`
whenever the script's content changes, `before_`/`after_` around writing files.

| Script | Does |
|---|---|
| `run_onchange_before_brew-bundle` | installs what's missing from `macos/Brewfile` |
| `run_once_after_iterm2-prefs-folder` | points iTerm2 at `macos/iterm2/` |
| `run_onchange_after_macos-prefs-apply` | app settings, repo -> Mac (counterpart of `scripts/macos-prefs-re-add.sh`) |

Managed: zsh (`.zshrc`, `.zshenv`, `.p10k.zsh`), nvim (LazyVim), Claude Code (`CLAUDE.md`),
iTerm2, Rectangle, UnnaturalScrollWheels.

## Not tracked (per machine)

- `~/.zshrc.local`, `~/.zshenv.local`: work aliases, paths, `KUBECONFIG`, etc.

## New machine

macOS needs [Homebrew](https://brew.sh) first. Fedora needs `zsh`, `git` and the prompt font first,
then set "Cascadia Code NF" as the terminal font:

```
sudo dnf install zsh git cascadia-code-nf-fonts
chsh -s $(which zsh)
```

Clone this repo anywhere (`~/personal/dotfiles` below), then:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
git clone <repo-url> ~/personal/dotfiles
~/.local/bin/chezmoi init --source ~/personal/dotfiles
~/.local/bin/chezmoi diff
~/.local/bin/chezmoi apply
```

After the first apply, open a new shell so `~/.local/bin` is on `PATH`.

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
- `edit`: edit the source copy; needed for templates (`.zshrc`)
- `cd`: open a shell in the repo
