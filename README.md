# dotfiles

My shell, editor and desktop setup, managed with [chezmoi](https://www.chezmoi.io/).
Works on macOS and Fedora with KDE Plasma. Clone it anywhere: chezmoi is pointed at the
clone, so you edit files in the repo and `chezmoi apply` writes them into `~`.

## What's managed

- **Everywhere:** zsh (`.zshrc`, `.zshenv`, `.p10k.zsh`) with Oh My Zsh, Powerlevel10k and
  plugins (cloned on first apply), nvim (LazyVim), Claude Code (settings, plugins, skills,
  agents, `CLAUDE.md`; see [Claude Code](#claude-code))
- **macOS:** apps and CLI tools from `macos/Brewfile`, iTerm2, Rectangle, UnnaturalScrollWheels
- **Fedora:** dnf packages, Flathub apps and the repos they need, zsh as the login shell
- **KDE Plasma:** settings (theme, effects, power, input, Konsole), the themes they use,
  Konsole colors and shortcuts, CaskaydiaCove Nerd Font

Not managed: `~/.zshrc.local` and `~/.zshenv.local`, for anything machine-specific or
work-only (aliases, paths, `KUBECONFIG`). Both are sourced if they exist.

## Day to day

```
chezmoi diff
chezmoi apply
chezmoi re-add
chezmoi edit ~/.zshrc
chezmoi cd
```

- `diff`: what `apply` would change in `~`
- `apply`: write the repo state into `~`, and run the setup scripts that are due
- `re-add`: pull edits made directly in `~` back into the repo (non-template files only)
- `edit`: edit the repo copy of a file; needed for templates (`.zshrc`)
- `cd`: open a shell in the repo

On macOS and KDE, `apply` and `re-add` also sync app settings that don't live in plain
dotfiles. See [macOS app settings](#app-settings) and [KDE settings](#settings).

After `re-add`, check `git diff`, then commit.

## macOS

### Setup

Install [Homebrew](https://brew.sh) first, then:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
git clone <repo-url> <path>
~/.local/bin/chezmoi init --source <path>
~/.local/bin/chezmoi diff
~/.local/bin/chezmoi apply
```

After the first apply, open a new shell so `~/.local/bin` is on `PATH`.

### What apply does

| Script | Does |
|---|---|
| `run_onchange_before_brew-bundle` | installs what's missing from `macos/Brewfile`; never upgrades or removes |
| `run_once_after_iterm2-prefs-folder` | points iTerm2 at `macos/iterm2/` |
| `run_onchange_after_macos-prefs-apply` | loads `macos/prefs/` into the apps (restarts them if running) |
| `run_onchange_after_go-tools` | installs the latest Go tools in its list (`gopls`, `kubeconform`) with `go install` |

### App settings

- **iTerm2** reads and writes `macos/iterm2/` directly. Changes show up in `git diff` by
  themselves.
- **Rectangle and UnnaturalScrollWheels** are saved as plists in `macos/prefs/`. `re-add`
  saves their current settings into the repo (`scripts/macos-prefs-re-add.sh`), and `apply`
  loads them whenever the plists change.

To sync another app, add `<app name> <preferences domain>` to `macos/prefs/apps`, then run
`chezmoi re-add`.

## Fedora

### Setup

From a terminal inside the Plasma session:

```
sudo dnf install git chezmoi
git clone <repo-url> <path>
chezmoi init --source <path>
chezmoi diff
chezmoi apply
```

`apply` asks for the sudo password when there's something to install. Log out and back in
afterwards, for the login shell and the KDE settings.

### What apply does

`run_onchange_before_fedora-packages` installs only what's missing, and never upgrades or
removes anything:

- RPM Fusion (free and nonfree), the vendor repos in `fedora/repos/*.repo` and the COPRs in
  `fedora/repos/coprs`
- dnf packages from `fedora/packages`
- Flathub (with Fedora's filter removed) and the apps in `fedora/flatpaks`
- zsh as the login shell

It runs again whenever one of those files changes.

`run_onchange_after_go-tools` then installs the Go tools in its list, as on macOS.

## KDE Plasma

### What apply does

| Script | Does |
|---|---|
| `run_before_kde-themes-install` | installs the themes the settings use, if missing: Layan (Plasma, GTK, Kvantum, cursors), Tela icons, Kuro splash |
| `run_onchange_after_kde-prefs-apply` | loads `fedora/prefs/` into KDE and Konsole, and sets touchpad options |

Both only run inside a Plasma session. From SSH or a TTY they are skipped, and run at the
next `apply` inside Plasma.

`apply` also installs the CaskaydiaCove Nerd Font into `~/.local/share/fonts` and the Layan
Konsole color scheme.

### Settings

`fedora/prefs/kde` lists only the KDE settings changed from the defaults, one per line,
tab-separated:

```
<file>  <group>  <key>  <value>
```

- `file`: relative to `~/.config`, or a path starting with `~/`
- `group`: nested groups written as `[A][B]`
- `value`: `(default)` removes the key, so KDE falls back to its default

Theme colors, window decoration and cursors come from the Layan global theme, so they aren't
listed. `fedora/prefs/konsole-shortcuts` does the same for Konsole shortcuts, which Konsole
keeps in XML files instead of KDE config files.

- **Change a listed setting** in System Settings or Konsole, then `chezmoi re-add`: the new
  value is saved into `fedora/prefs/` (`scripts/kde-prefs-re-add.sh`).
- **Sync a new setting** by adding its line. `re-add` also prints the settings that changed
  since its last run, in the files `fedora/prefs/kde` already uses, as lines ready to paste.
  For other files, find the file in `~/.config` that changed and write the line by hand.
- **Pulling from another machine:** when `fedora/prefs/` changes, the next `apply` writes every
  listed setting without asking. Run `re-add` before pulling if you changed settings here.
- `chezmoi diff` doesn't show KDE settings. To see what changed locally, run `re-add` and
  `git diff`.
- Touchpad settings (natural scrolling, click method, scroll speed) are in the apply script:
  KDE stores them per touchpad model, so the script finds the machine's touchpads.

### Themes

Themes are installed only when missing, so they don't update by themselves. To update one,
delete its folder (the paths are in `run_before_kde-themes-install`) and run `chezmoi apply`.

A reinstalled Layan overwrites the transparency fix in `fedora/prefs/kde`. Load the settings
again with:

```
chezmoi execute-template < "$(chezmoi source-path)/.chezmoiscripts/run_onchange_after_kde-prefs-apply.sh.tmpl" | bash
```

### Manual steps

Wallpapers and the panel layout aren't synced: Plasma stores panels per screen, with internal
IDs. On each screen:

- Top bar: application launcher, global menu, clock in the center, system tray
- Bottom dock: floating, translucent, visibility "Dodge windows", icon-only task manager

For another monitor, use "Clone Panel" in the panel's Edit Mode.

## Claude Code

The repo is the source of truth for Claude Code, so the setup is the same on every machine
and with any claude.ai account.

### What's in the repo

| Repo path (`home/private_dot_claude/`) | What it is |
|---|---|
| `settings.json` | Settings, the plugin marketplaces (`extraKnownMarketplaces`) and the plugins to turn on (`enabledPlugins`) |
| `skills/` | My own skills: `dotfiles` (change files here at the source), `writing-style`, `fact-check`, `read-gdocs` |
| `agents/` | My own subagents: `doc-reviewer` (runs `fact-check` on a document in a fresh context) |
| `CLAUDE.md` | Global instructions |

Tools the plugins need are installed with everything else: `gopls` (for `gopls-lsp`) by
`run_onchange_after_go-tools`, and `pandoc` and `poppler` (for `document-skills`) from
`macos/Brewfile` and `fedora/packages`.

Not in the repo:

- **claude.ai connectors (MCP):** added and signed in to at
  [claude.ai/customize/connectors](https://claude.ai/customize/connectors). Claude Code
  picks them up when signed in with that account. On a new account, connect them again.
- **`~/.claude.json`:** Claude Code's own state, including per-project `/mcp` toggles and
  the Chrome "Enabled by default" setting. Not synced.
- **Skills and plugins from claude.ai:** sync is off (`syncClaudeAiSkills`,
  `syncClaudeAiPlugins`), so claude.ai doesn't add copies on top of the repo's.

### New machine

1. `chezmoi apply` writes `~/.claude`.
2. Start `claude` and sign in.
3. In that first session, Claude Code clones the marketplaces in `settings.json` and
   downloads the plugins in the background. Run `/reload-plugins` (or start a new session)
   to load them, then check with `claude plugin list`.

### Changes

- **Settings and plugins:** change them in Claude Code (`/config`, `/plugin`,
  `claude plugin install`), which writes `~/.claude/settings.json`. Then
  `chezmoi re-add ~/.claude/settings.json`. Claude Code may reorder keys; only value
  changes matter in `git diff`.
- **A new skill of my own:** add it under `home/private_dot_claude/skills/<name>/` and run
  `chezmoi apply`. To also use it in claude.ai chat, upload it there from the repo copy.

### Web and other assistants

`ai/instructions.md` holds my instructions for chat assistants. For claude.ai ("Instructions
for Claude" in Settings) or any other assistant, paste it followed by
`home/private_dot_claude/skills/writing-style/style.md`. Some platforms cap the length of that
field. On claude.ai, also upload the `fact-check` skill from
`home/private_dot_claude/skills/fact-check/`.

### Review tools

| To check | Use |
|---|---|
| Bugs in a diff, branch or PR | `/code-review` (built in) |
| Cleanup and simplification | `/simplify` (built in) |
| Coding standards and match with the spec | `/mattpocock-skills:code-review` (standards need a `CODING_STANDARDS.md`) |
| Security | `/security-review` (built in), or `/claude-security` for a deep scan |
| That a change actually works | `/verify`, `/run` (built in) |
| A document or runbook | "review <doc>" or "fact check <doc>" (`doc-reviewer`) |
| Shell scripts, Helm charts | `shellcheck`, `helm lint`, `helm template ... \| kubeconform` |

## How the repo works

### Layout

```
home/                         chezmoi source, maps to ~ (see .chezmoiroot)
  .chezmoi.toml.tmpl          chezmoi config: source dir, re-add hooks
  .chezmoiexternal.toml.tmpl  Oh My Zsh, Powerlevel10k, zsh plugins, CaskaydiaCove font
  .chezmoiscripts/            setup scripts run by apply
  private_dot_claude/         Claude Code: settings, skills, agents, CLAUDE.md
ai/                           instructions for web chat assistants
macos/
  Brewfile                    apps and CLI tools
  iterm2/                     iTerm2 prefs, read and written by iTerm2
  prefs/                      app settings as plists, and the list of synced apps
fedora/
  packages, flatpaks          dnf packages, Flathub apps
  repos/                      vendor .repo files, COPRs
  prefs/                      KDE settings and Konsole shortcuts
scripts/                      re-add hooks: settings, machine -> repo
```

### Scripts

The filename prefix tells chezmoi when to run a script in `home/.chezmoiscripts/`:

- `run_` on every apply, `run_once_` once per machine, `run_onchange_` whenever the rendered
  script changes. Scripts that hash a data file in a comment rerun when that file changes.
- `before_` / `after_`: before or after chezmoi writes files. Scripts in the same phase run
  in alphabetical order.

Scripts that apply to only one OS or desktop are templates that render empty elsewhere.
chezmoi skips empty scripts without recording them, so they run later on a machine where they
apply.

### Settings sync

App settings that aren't plain dotfiles are synced by a pair of scripts, named after the
chezmoi command that runs them:

- `<name>-prefs-apply`: repo -> machine, an `onchange` script run by `chezmoi apply`
- `scripts/<name>-prefs-re-add.sh`: machine -> repo, run by a `re-add` hook in
  `.chezmoi.toml.tmpl` (can also be run by hand)

Each pair reads and writes only the settings listed in its prefs folder, and leaves
everything else alone. Current pairs: `macos` (`macos/prefs/`) and `kde` (`fedora/prefs/`).
