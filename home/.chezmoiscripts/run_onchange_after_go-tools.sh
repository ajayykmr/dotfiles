#!/bin/sh
# Install the latest version of these Go tools with `go install`, into ~/go/bin
# (on PATH via ~/.zshrc). Go itself comes from macos/Brewfile or
# fedora/packages. Re-runs whenever this file changes.
set -eu

# Homebrew isn't on PATH yet during the first apply on macOS.
if [ -x /opt/homebrew/bin/go ]; then
  PATH="/opt/homebrew/bin:$PATH"
fi

for pkg in \
  golang.org/x/tools/gopls \
  github.com/yannh/kubeconform/cmd/kubeconform \
  ; do
  go install "$pkg@latest"
done
