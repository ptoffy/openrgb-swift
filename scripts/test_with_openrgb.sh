#!/usr/bin/env bash
set -euo pipefail

# Run the OpenRGB server in Docker and execute the Swift test-suite against it.
#
# Usage:
#   ./scripts/test_with_openrgb.sh
# Environment variables (optional):
#   OPENRGB_IMAGE - Docker image to run (default: openrgb/openrgb:latest)
#   OPENRGB_CONTAINER_NAME - Container name (default: openrgb-test-server)
#   OPENRGB_PORT - Host port to map to OpenRGB server (default: 6742)
#   OPENRGB_ARGS - Extra args to pass to the OpenRGB process inside the container
#                  (default: "--server --listen 0.0.0.0")

# IMAGE="${OPENRGB_IMAGE:-swensorm/openrgb:release_0.9}"
IMAGE_NAME="swensorm/openrgb:release_0.9"
CONTAINER_NAME="${OPENRGB_CONTAINER_NAME:-openrgb-test-server}"
HOST_PORT="${OPENRGB_PORT:-6742}"
CONTAINER_PORT="${OPENRGB_PORT:-6742}"
OPENRGB_ARGS="${OPENRGB_ARGS:---server --listen 0.0.0.0}"

echo "🌠 Using image: $IMAGE_NAME"

echo "🛬 Pulling image..."
docker pull "$IMAGE_NAME"

echo "🧱 Building image..."
docker build -t openrgb-server scripts/.

echo "🏴‍☠️ Removing any existing container named $CONTAINER_NAME"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

echo "🚀 Starting container $CONTAINER_NAME"
# Start container without --rm so we can control teardown explicitly via trap
docker run -d --platform linux/amd64 --name "$CONTAINER_NAME" -p "$HOST_PORT:$CONTAINER_PORT" "$IMAGE_NAME" $OPENRGB_ARGS >/dev/null

echo "⏲️ Waiting for OpenRGB to accept connections on localhost:$HOST_PORT"

wait_for_port() {
  local host=localhost
  local port=$1
  local tries=30
  local i=0

  if command -v nc >/dev/null 2>&1; then
    while ! nc -z "$host" "$port"; do
      i=$((i+1))
      if [ "$i" -ge "$tries" ]; then
        return 1
      fi
      sleep 1
    done
    return 0
  else
    echo "Warning: 'nc' not found; sleeping to allow server to start (adjust if needed)"
    sleep 5
    return 0
  fi
}

if ! wait_for_port "$HOST_PORT"; then
  echo "😵‍💫 OpenRGB did not start in time; container logs:"
  docker logs "$CONTAINER_NAME" --tail 200 || true
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  exit 1
fi

echo "🎉 OpenRGB is accepting connections at localhost:$HOST_PORT"

swift test

cleanup() {
  echo "👋 Stopping and removing container $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap cleanup INT TERM EXIT

exit 0
