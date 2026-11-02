#!/usr/bin/env bash
# Start Chromium on the VNC display.
set -euo pipefail

profile="$HOME/.config/chromium"

# A profile kept in a volume still holds the lock from the previous
# container, whose hostname differs, so Chromium would refuse to open it.
rm -f "$profile"/Singleton{Cookie,Lock,Socket}

# Docker's default seccomp profile blocks the namespaces Chromium's sandbox
# needs, so the container is the isolation boundary.
exec /usr/local/bin/wait-for-x.sh chromium \
  --no-sandbox \
  --no-first-run \
  --start-maximized \
  --user-data-dir="$profile"
