#!/usr/bin/env bash
# Check the configuration, then run the container command (supervisord).
set -euo pipefail

if [[ ! "${VNC_RESOLUTION:-}" =~ ^[0-9]+x[0-9]+$ ]]; then
  echo "VNC_RESOLUTION must look like 1280x720, got '${VNC_RESOLUTION:-}'" >&2
  exit 1
fi

export VNC_USERNAME="${VNC_USERNAME:-browser}"

if [[ -n "${VNC_PASSWORD:-}" ]]; then
  if [[ "$VNC_USERNAME" == *:* ]]; then
    echo "VNC_USERNAME must not contain ':'" >&2
    exit 1
  fi
else
  echo "WARNING: VNC_PASSWORD is not set. Anyone who can reach port 6080 controls the browser." >&2
fi

exec "$@"
