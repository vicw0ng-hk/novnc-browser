#!/usr/bin/env bash
# Start a container from IMAGE and check that it comes up healthy.
# Usage: tests/smoke.sh [IMAGE]
set -euo pipefail

image="${1:-novnc-browser:dev}"
name="novnc-browser-smoke-$$"

cleanup() {
  docker rm --force "$name" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  docker logs "$name" >&2 || true
  exit 1
}

docker run --detach --name "$name" "$image" >/dev/null
sleep 3

[[ "$(docker inspect --format '{{.State.Running}}' "$name")" == true ]] ||
  fail "container exited"

[[ "$(docker exec "$name" id -u)" != 0 ]] ||
  fail "container runs as root"

echo "PASS: $image"
