#!/usr/bin/env bash
# Serve noVNC on port 6080 and proxy its WebSocket to the VNC server.
# Setting VNC_PASSWORD puts both behind HTTP Basic auth.
set -euo pipefail

args=(--web /usr/share/novnc --file-only)
if [[ -n "${VNC_PASSWORD:-}" ]]; then
  args+=(
    --web-auth
    --auth-plugin websockify.auth_plugins.BasicHTTPAuth
    --auth-source "$VNC_USERNAME:$VNC_PASSWORD"
  )
fi

exec websockify "${args[@]}" 6080 localhost:5900
