#!/usr/bin/env bash
# Wait for the X server on $DISPLAY, then run the given command.
# Usage: wait-for-x.sh COMMAND [ARG...]
set -euo pipefail

socket="/tmp/.X11-unix/X${DISPLAY#:}"
for _ in $(seq 50); do
  if [[ -S "$socket" ]]; then
    exec "$@"
  fi
  sleep 0.1
done

echo "X server on $DISPLAY did not start" >&2
exit 1
