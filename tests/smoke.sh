#!/usr/bin/env bash
# Start containers from IMAGE and check that noVNC serves its page and
# reaches the VNC server, with and without a password.
# Usage: tests/smoke.sh [IMAGE]
set -euo pipefail

image="${1:-novnc-browser:dev}"
prefix="novnc-browser-smoke-$$"
# Longer than 8 characters, which VNC's own password auth would truncate.
password="correct horse battery staple"
current=""

cleanup() {
  docker rm --force "$prefix-open" "$prefix-auth" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  if [[ -n "$current" ]]; then
    docker logs "$current" 2>&1 | tail -n 50 >&2 || true
  fi
  exit 1
}

pass() {
  echo "ok: $*"
}

# Start a detached container and print the host port that noVNC is on.
start() {
  local name="$1" address
  shift
  docker run --detach --name "$name" --publish 127.0.0.1::6080 "$@" "$image" >/dev/null
  address="$(docker port "$name" 6080/tcp | head -n 1)"
  echo "${address##*:}"
}

http_status() {
  curl --silent --output /dev/null --write-out '%{http_code}' "$@"
}

basic_auth() {
  printf 'Authorization: Basic %s' "$(printf '%s' "$1" | base64)"
}

# Open a WebSocket to noVNC on PORT and succeed if the VNC server's RFB
# greeting comes back through it. Extra arguments are sent as headers.
rfb_greeting() {
  local port="$1" header line
  shift
  { exec 3<>"/dev/tcp/127.0.0.1/$port"; } 2>/dev/null || return 1
  {
    printf 'GET /websockify HTTP/1.1\r\n'
    printf 'Host: 127.0.0.1:%s\r\n' "$port"
    printf 'Upgrade: websocket\r\nConnection: Upgrade\r\n'
    printf 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n'
    printf 'Sec-WebSocket-Version: 13\r\nSec-WebSocket-Protocol: binary\r\n'
    for header in "$@"; do
      printf '%s\r\n' "$header"
    done
    printf '\r\n'
  } >&3
  while IFS= read -r -t 5 line <&3; do
    if [[ "$line" == *"RFB 003."* ]]; then
      exec 3>&-
      return 0
    fi
  done
  exec 3>&-
  return 1
}

# Retry a command once a second for up to 60 seconds.
eventually() {
  for _ in $(seq 60); do
    if "$@"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# Succeed if supervisord reports every program running.
all_running() {
  docker exec "$current" supervisorctl status >/dev/null
}

chromium_pid() {
  docker exec "$current" supervisorctl status chromium | sed -n 's/.*pid \([0-9]*\),.*/\1/p'
}

echo "Testing $image"

# Without a password
current="$prefix-open"
port="$(start "$current")"

eventually rfb_greeting "$port" ||
  fail "no RFB greeting through the noVNC WebSocket"
pass "noVNC WebSocket reaches the VNC server"

[[ "$(http_status "http://127.0.0.1:$port/")" == 200 ]] || fail "GET / did not return 200"
[[ "$(http_status "http://127.0.0.1:$port/vnc.html")" == 200 ]] || fail "GET /vnc.html did not return 200"
pass "noVNC page is served without a password"

eventually all_running || fail "not all supervisord programs are running"
pid="$(chromium_pid)"
sleep 5
[[ -n "$pid" && "$(chromium_pid)" == "$pid" ]] || fail "Chromium restarted or is not running"
pass "Chromium stays up"

[[ "$(docker exec "$current" id -u)" != 0 ]] || fail "container runs as root"
pass "container runs as a non-root user"

# With a password
current="$prefix-auth"
port="$(start "$current" --env VNC_PASSWORD="$password")"

eventually rfb_greeting "$port" "$(basic_auth "browser:$password")" ||
  fail "no RFB greeting with valid credentials"
pass "noVNC WebSocket reaches the VNC server with valid credentials"

! rfb_greeting "$port" || fail "WebSocket works without credentials"
! rfb_greeting "$port" "$(basic_auth "browser:wrong")" || fail "WebSocket works with a wrong password"
pass "WebSocket rejects missing or wrong credentials"

[[ "$(http_status "http://127.0.0.1:$port/")" == 401 ]] || fail "GET / without credentials did not return 401"
[[ "$(http_status --user "browser:wrong" "http://127.0.0.1:$port/")" == 401 ]] ||
  fail "GET / with a wrong password did not return 401"
[[ "$(http_status --user "browser:$password" "http://127.0.0.1:$port/")" == 200 ]] ||
  fail "GET / with valid credentials did not return 200"
pass "noVNC page requires the password"

# Invalid configuration
current=""
if docker run --rm --env VNC_RESOLUTION=large "$image" >/dev/null 2>&1; then
  fail "container started with VNC_RESOLUTION=large"
fi
pass "container refuses an invalid VNC_RESOLUTION"

echo "PASS: $image"
