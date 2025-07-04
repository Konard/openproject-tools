#!/usr/bin/env bash
set -euo pipefail

# Test script for OpenProject 16.1.1 all-in-one Docker container
# Usage: ./test_openproject_allinone.sh

IMAGE="openproject/openproject:16.1.1"
CONTAINER_NAME="openproject-test"
HOST_PORT=8080

# Generate secret if not provided
echo "Generating OPENPROJECT_SECRET_KEY_BASE..."
export OPENPROJECT_SECRET_KEY_BASE=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)

echo "Cleaning up any existing container named $CONTAINER_NAME..."
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# Run the container
echo "Starting OpenProject container ($IMAGE) on port $HOST_PORT..."
docker run -d --name "$CONTAINER_NAME" -p "$HOST_PORT:80" \
  -e OPENPROJECT_SECRET_KEY_BASE="$OPENPROJECT_SECRET_KEY_BASE" \
  -e OPENPROJECT_HOST__NAME="localhost:$HOST_PORT" \
  -e OPENPROJECT_HTTPS=false \
  -e OPENPROJECT_DEFAULT__LANGUAGE=en \
  "$IMAGE"

# Define and print URLs to test
HEALTH_URL="http://localhost:$HOST_PORT/health_checks/default"
LOGIN_URL="http://localhost:$HOST_PORT/login"
echo "Health URL: $HEALTH_URL"
echo "Login URL: $LOGIN_URL"

# Wait for health endpoint
echo -n "Waiting for OpenProject to become healthy"
for i in $(seq 1 60); do
  if curl -fs "$HEALTH_URL" >/dev/null; then
    echo " - healthy!"
    break
  fi
  echo -n "."
  sleep 5
  if [ "$i" -eq 60 ]; then
    echo "\nTimed out waiting for healthcheck."
    docker logs --tail 50 "$CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
    exit 1
  fi
done

# Show recent logs
echo "--- Container logs (last 20 lines) ---"
docker logs --tail 20 "$CONTAINER_NAME"

# Verify login page reachability
echo "Testing login page..."
if curl -fs "$LOGIN_URL" >/dev/null; then
  echo "Login page reachable."
else
  echo "Login page failed."
  docker logs "$CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME"
  exit 1
fi

# Cleanup
echo "Stopping and removing container..."
docker rm -f "$CONTAINER_NAME"

echo "OpenProject all-in-one Docker test succeeded!" 